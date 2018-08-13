CFLAGS += -g -DDEBUG -Ishared -DLINUX_X86 -Os -fPIC
LDLIBS = -lpthread -lrt

# SIGEV_NOTIFY_SIGNAL is used to enable SIGEV_SIGNAL and disable SIGEV_THREAD
# USER should define SIGEV_NOTIFY_SIGNAL=y to enable SIGEV_SIGNAL
# or other value to disable SIGEV_SIGNAL
ifeq ($(SIGEV_NOTIFY_SIGNAL), y)
CFLAGS += -DSIGEV_NOTIFY_SIGNAL
endif

.PHONY: all clean

Qcmbr: Qcmbr.o diag_pkt_handler.o tlvCmd_if_Qdart.o Socket.o q_os_if.o
	$(CC)   Qcmbr.o diag_pkt_handler.o tlvCmd_if_Qdart.o Socket.o q_os_if.o  -lrt -rdynamic -lm -lpthread -ldl -o Qcmbr

Qcmbr.o : Qcmbr.c Qcmbr.h
	$(CC) -c $(CFLAGS) Qcmbr.c
diag_pkt_handler.o : diag_pkt_handler.c
	$(CC) -c $(CFLAGS) diag_pkt_handler.c
tlvCmd_if_Qdart.o : tlvCmd_if_Qdart.c
	$(CC) -c $(CFLAGS) tlvCmd_if_Qdart.c
Socket.o  : ./shared/Socket.c ./shared/Socket.h
	$(CC) -c $(CFLAGS) ./shared/Socket.c
q_os_if.o : q_os_if.c
	$(CC) -c $(CFLAGS) q_os_if.c

clean:
	-$(RM) *.o
	-$(RM) Qcmbr

