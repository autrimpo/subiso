CC                 := gcc
UCW_CFLAGS         := $(shell pkg-config --cflags libucw)
UCW_LFLAGS         := $(shell pkg-config --libs libucw)
CFLAGS             := -std=gnu99 -c -MMD -MP $(UCW_CFLAGS) -Wno-implicit-function-declaration -O3
LFLAGS             := -std=gnu99 $(UCW_LFLAGS) -pthread
SOURCEDIR          := src
BUILDDIR           := build
C_FILES            := $(wildcard $(SOURCEDIR)/*.c)
OBJ_FILES          := $(addprefix $(BUILDDIR)/,$(notdir $(C_FILES:.c=.o)))
DEP_FILES          := $(addprefix $(BUILDDIR)/,$(notdir $(C_FILES:.c=.d)))
BIN_NAME           := grs
UCW_VER			       := libucw-6.5
UCW_SRC            := http://www.ucw.cz/libucw/download/$(UCW_VER).tar.gz
UCW_CONF           := CONFIG_LOCAL -CONFIG_SHARED -CONFIG_XML -CONFIG_JSON -CONFIG_UCW_UTILS

.PHONY: clean debug

all : libucw_check $(BIN_NAME)

libucw_check :
ifneq ($(shell pkg-config --libs libucw), -lucw-6.5)
ifneq ($(shell ls $(UCW_VER).tar.gz),$(UCW_VER).tar.gz)
	wget $(UCW_SRC)
endif
ifeq ($(wildcard $(UCW_VER)/.*),)
	tar xzf $(UCW_VER).tar.gz
	cd $(UCW_VER) && ./configure $(UCW_CONF)
	$(MAKE) -C $(UCW_VER)
endif
endif

$(BIN_NAME) : UCW_LIBPATH = $(shell find . -name '$(UCW_VER).a' | grep lib/)
$(BIN_NAME) : LFLAGS_STATIC = -std=gnu99 -pthread
$(BIN_NAME) : $(OBJ_FILES)
ifneq ($(shell pkg-config --libs libucw), -lucw-6.5)
	$(CC) $(LFLAGS_STATIC) $(OBJ_FILES) $(UCW_LIBPATH) -o $(BIN_NAME)
else
	$(CC) $(LFLAGS) $(OBJ_FILES) -o $(BIN_NAME)
endif

$(BUILDDIR)/%.o : UCW_CFLAGS_STATIC = -I$(shell find . -name 'include' -type d)
$(BUILDDIR)/%.o : CFLAGS_STATIC = -std=gnu99 -c -MMD -MP $(UCW_CFLAGS_STATIC) -Wno-implicit-function-declaration -O3
$(BUILDDIR)/%.o : $(SOURCEDIR)/%.c
ifneq ($(shell pkg-config --libs libucw), -lucw-6.5)
	$(CC) $(CFLAGS_STATIC) $< -o $@
else
	$(CC) $(CFLAGS) $< -o $@
endif

tests: CFLAGS += -DTESTING
tests: $(BIN_NAME)

debug: CFLAGS += -DLOCAL_DEBUG -g
debug: $(BIN_NAME)

clean:
	rm -f $(OBJ_FILES) $(DEP_FILES) $(BIN_NAME) $(UCW_VER).tar.gz
	rm -rf $(UCW_VER)

-include $(DEP_FILES)
