
KERNEL 		:= kernel.bin
ENTRYPOINT	:= 0x30400
ENTRYOFFSET	:= 0x400


CFLAGS 		+= -I include/ -c -fno-builtin
ASMKFLAGS 	+= -I include/ -f elf
LDFLAGS 	+= -Ttext $(ENTRYPOINT)
DASMFLAGS	+= -u -o $(ENTRYPOINT) -e $(ENTRYOFFSET)


SRCS_KLIB := $(wildcard ./klib/*.c)
SRCS_KLIB += $(wildcard ./klib/*.asm)
DEPS_KLIB := $(SRCS_KLIB:%.c=%.d)
DEPS_KLIB := $(filter %.d, $(DEPS_KLIB))
OBJS_KLIB := $(SRCS_KLIB:%.c=%.o)
OBJS_KLIB += $(SRCS_KLIB:%.asm=%.a)
OBJS_KLIB := $(filter %.a %.o, $(OBJS_KLIB))

SRCS_BOOT := boot.asm start.c
DEPS_BOOT := $(SRCS_BOOT:%.c=%.d)
DEPS_BOOT := $(filter %.d, $(DEPS_BOOT))
OBJS_BOOT := boot.a start.o


$(KERNEL): $(OBJS_BOOT) $(OBJS_KLIB)
	@echo -e "  LD\t$(notdir $@)"
	@$(LD) $(LDFLAGS) -o $@  $(OBJS_BOOT) $(OBJS_KLIB)
	@cp $(KERNEL) $(KERNEL).unstrip
	@echo -e "  STRIP\t$(notdir $@)"
	@$(STRIP) $(KERNEL)



.PHONY: clean
clean :
	rm -f $(KERNEL) $(KERNEL).unstrip  $(OBJS_KLIB) $(OBJS_BOOT) $(DEPS_KLIB) $(DEPS_BOOT)



%.a: %.asm
	@echo -e "  ASM\t$(notdir $@)"
	@$(ASM) $(ASMKFLAGS) -o $@ $<


%.o: %.c
	@echo -e "  CC\t$(notdir $@)"
	@$(CC) $(CFLAGS) -o $@ $<


%.d: %.c
	@echo -e "  DEP\t$(notdir $@)"
	@set -e; \
	$(CC) -E -MM $(CFLAGS) $(filter %.c, $^) >$@.tmp;\
	sed 's,\(.*\)\.o[ :]*,\1.o $@ : ,g' < $@.tmp >$@;\
	rm -rf $@.tmp



-include 	$(DEPS_KLIB) $(DEPS_BOOT)

