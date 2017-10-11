# This is a simple Makefile that generates client library source code
# for Google APIs using Protocol Buffers and gRPC for any supported
# language. However, it does not compile the generated code into final
# libraries that can be directly used with application code.
#
# Syntax example: make OUTPUT=./output LANGUAGE=java
#

# Install prefix
PREFIX ?= /opt/build/googleapis

# Choose the output directory
OUTPUT ?= ./gens

# Choose binary output directory
OUTPUT_BIN ?= $(OUTPUT)

# Choose the target language.
LANGUAGE ?= cpp

# Choose grpc plugin
#GRPCPLUGIN ?= /usr/local/bin/grpc_$(LANGUAGE)_plugin
GRPCPLUGIN ?= /opt/build/grpc/bin/grpc_$(LANGUAGE)_plugin

# Choose grpc include
GRPCINCLUDE ?= /opt/build/grpc/include

# Choose the proto include directory.
#PROTOINCLUDE ?= /usr/local/include
PROTOINCLUDE ?= /opt/build/protobuf/include

# Choose protoc binary
#PROTOC ?= protoc
PROTOC ?= /opt/build/protobuf/bin/protoc

# Compile the entire repository
#
# NOTE: if "protoc" command is not in the PATH, you need to modify this file.
#

ifeq ($(LANGUAGE),go)
$(error Go source files are not generated from this repository. See: https://github.com/google/go-genproto)
endif

FLAGS+= --proto_path=.:$(PROTOINCLUDE)
FLAGS+= --$(LANGUAGE)_out=$(OUTPUT) --grpc_out=$(OUTPUT)
FLAGS+=	--plugin=protoc-gen-grpc=$(GRPCPLUGIN)

SUFFIX_PROTO_SRC:= pb.cc
SUFFIX_GRPC_SRC:= grpc.pb.cc
SUFFIX_PROTO_HDR:= pb.h
SUFFIX_GRPC_HDR:= grpc.pb.h
SUFFIX_PROTO_OBJ:= pb.o
SUFFIX_GRPC_OBJ:= grpc.pb.o

API_PROTOS:= $(shell find google -type f -name '*.proto')
#PROTOBUF_PROTOS:= $(shell find $(PROTOINCLUDE)/google/protobuf -type f -name '*.proto')
PROTOBUF_PROTOS:=
PROTOS:= $(API_PROTOS) $(PROTOBUF_PROTOS)

BASEPROTOS:= $(patsubst $(PROTOINCLUDE)/%,%,$(PROTOS))

PROTO_SRCS = $(BASEPROTOS:.proto=.$(SUFFIX_PROTO_SRC))
GRPC_SRCS = $(BASEPROTOS:.proto=.$(SUFFIX_GRPC_SRC))

PROTO_HDRS = $(BASEPROTOS:.proto=.$(SUFFIX_PROTO_HDR))
GRPC_HDRS = $(BASEPROTOS:.proto=.$(SUFFIX_GRPC_HDR))

PROTO_OBJS = $(PROTO_SRCS:.$(SUFFIX_PROTO_SRC)=.$(SUFFIX_PROTO_OBJ))
GRPC_OBJS = $(GRPC_SRCS:.$(SUFFIX_GRPC_SRC)=.$(SUFFIX_GRPC_OBJ))

DEPS_PROTO:= $(PROTOS)
DEPS_SRC:= $(addprefix $(OUTPUT)/,$(PROTO_SRCS) $(GRPC_SRCS))
DEPS_HDR:= $(addprefix $(OUTPUT)/include/,$(PROTO_HDRS) $(GRPC_HDRS))
DEPS_OBJ:= $(addprefix $(OUTPUT_BIN)/,$(PROTO_OBJS) $(GRPC_OBJS))

INSTALL_HDR:= $(addprefix $(OUTPUT)/include/,$(API_PROTOS:.proto=.$(SUFFIX_PROTO_HDR)) $(API_PROTOS:.proto=.$(SUFFIX_GRPC_HDR)))

DIR_OBJ:= $(sort $(dir $(DEPS_OBJ)))

.PHONY: all libs install clean

all: libs

install: libgoogleapis.a $(DEPS_HDR) | $(PREFIX)
	cp -f libgoogleapis.a $(PREFIX)/lib/
#	cp -rf $(INSTALL_HDR) $(PREFIX)/include
	cp -rf $(OUTPUT)/include $(PREFIX)

$(PREFIX): 
	mkdir -p $(PREFIX)
	mkdir -p $(PREFIX)/include
	mkdir -p $(PREFIX)/lib

libs: libgoogleapis.a

libgoogleapis.a: $(DEPS_OBJ)
	ar rcs libgoogleapis.a $(DEPS_OBJ)

$(DEPS_OBJ): $(DEPS_SRC) $(DEPS_HDR)

$(DEPS_SRC) $(DEPS_HDR): $(DEPS_PROTO)

$(OUTPUT_BIN)/%.$(SUFFIX_PROTO_OBJ): $(OUTPUT)/%.$(SUFFIX_PROTO_SRC) $(DEPS_HDR) | $(DIR_OBJ)
	g++ -std=c++11 -I$(OUTPUT)/include -I$(PROTOINCLUDE) -I$(GRPCINCLUDE) -c -g -O2 -o $@ $<

$(DIR_OBJ):
	mkdir -p $@

$(OUTPUT)/%.$(SUFFIX_PROTO_SRC) $(OUTPUT)/%.$(SUFFIX_GRPC_SRC) $(OUTPUT)/include/%.$(SUFFIX_PROTO_HDR) $(OUTPUT)/include/%.$(SUFFIX_GRPC_HDR): %.proto | $(OUTPUT)
	$(PROTOC) $(FLAGS) $<
	mkdir --parents $(OUTPUT)/include/$(dir $*)
	mv $(OUTPUT)/$*.$(SUFFIX_PROTO_HDR) $(OUTPUT)/include/$*.$(SUFFIX_PROTO_HDR)
	mv $(OUTPUT)/$*.$(SUFFIX_GRPC_HDR) $(OUTPUT)/include/$*.$(SUFFIX_GRPC_HDR)

$(OUTPUT)/%.$(SUFFIX_PROTO_SRC) $(OUTPUT)/%.$(SUFFIX_GRPC_SRC) $(OUTPUT)/include/%.$(SUFFIX_PROTO_HDR) $(OUTPUT)/include/%.$(SUFFIX_GRPC_HDR): $(PROTOINCLUDE)/%.proto | $(OUTPUT)
	$(PROTOC) $(FLAGS) $<
	mkdir --parents $(OUTPUT)/include/$(dir $*)
	mv $(OUTPUT)/$*.$(SUFFIX_PROTO_HDR) $(OUTPUT)/include/$*.$(SUFFIX_PROTO_HDR)
	mv $(OUTPUT)/$*.$(SUFFIX_GRPC_HDR) $(OUTPUT)/include/$*.$(SUFFIX_GRPC_HDR)

$(OUTPUT):
	mkdir -p $@
	mkdir -p $@/include

clean:
	rm $(patsubst %,$(OUTPUT)/%,$(DEPS)) 2> /dev/null
	rm -rd $(OUTPUT)
