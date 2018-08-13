
/* 
Copyright (c) 2013 Qualcomm Atheros, Inc.
All Rights Reserved. 
Qualcomm Atheros Confidential and Proprietary. 
*/  

/* qcmbr.c - Qcmbr main */

#ifdef _WINDOWS
 #include <windows.h>
#include <conio.h>
#else
 #define HANDLE int
#endif


#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
#include <ctype.h>
#include <string.h>

#include "Socket.h"
#include "Qcmbr.h"

const char *QCMBR_VERSION = "QCMBR VERSION : 002.000.000.000";

HANDLE ghMutex=NULL;
int    gFromQ = 0;

#define MAX_HS_WIDTH    16
#define DbgPrint    printf
void DispHexString(unsigned char *pkt_buffer, int recvsize)
{
  int i, j, k;

  for (i=0; i<recvsize; i+=MAX_HS_WIDTH) {
    DbgPrint("[%4.4d] ",i);
    for (j=i, k=0; (k<MAX_HS_WIDTH) && ((j+k)<recvsize); k++)
      DbgPrint("0x%2.2X ",(pkt_buffer[j+k])&0xFF);
    for (; (k<MAX_HS_WIDTH ); k++)
      DbgPrint("     ");
    DbgPrint(" ");
    for (j=i, k=0; (k<MAX_HS_WIDTH) && ((j+k)<recvsize); k++)
      DbgPrint("%c",(pkt_buffer[j+k]>32)?pkt_buffer[j+k]:'.');
    DbgPrint("\n");
  }
}

void receiveCmdReturn1(void *buf)
{
    A_UINT8 *reply = (A_UINT8*)buf;
    A_UINT32 length =0;

    length = *(A_UINT32 *)&(reply[0]);

    printf("receiveCmdReturn1() TLV length got %u\n",length);
//    DispHexString((unsigned char *)buf,length);
}


#ifdef _WINDOWS

void CloseAll()
{
  extern HANDLE DevHandle;
  extern DWORD CloseArt2Device(HANDLE DevHandle);
  void ClientClose(int client);
  int it;

  printf("Closing all TCP socket handles.\n");
  for (it=0; it<MCLIENT; it++)
	ClientClose(it);

  if( DevHandle ) 
  {
    printf("Closing Device driver handles.\n");
    CloseArt2Device(DevHandle);
    DevHandle = NULL;
  }

  if (ghMutex)
	  CloseHandle(ghMutex);
}

static void ReLaunch()
{
	char *cmdLine = GetCommandLine();

	STARTUPINFO si;
    PROCESS_INFORMATION pi;
	char qcmbr_path[MAX_PATH];

	GetModuleFileName(NULL, qcmbr_path, MAX_PATH);

    ZeroMemory( &si, sizeof(si) );
    si.cb = sizeof(si);
    ZeroMemory( &pi, sizeof(pi) );

    if (!CreateProcess(qcmbr_path,    // No module name (use command line)
                       cmdLine,        //argv[1],        // Command line
                       NULL,           // Process handle not inheritable
                       NULL,           // Thread handle not inheritable
                       FALSE,          // Set handle inheritance to FALSE
                       0,              // No creation flags
                       NULL,           // Use parent's environment block
                       NULL,           // Use parent's starting directory 
                       &si,            // Pointer to STARTUPINFO structure
                       &pi )           // Pointer to PROCESS_INFORMATION structure
                       ) 
    {
      printf("CreateProcess failed [%s %s](%d).\n", qcmbr_path, cmdLine, GetLastError());
    }
    exit(-1);
}

BOOL CtrlHandler( DWORD fdwCtrlType ) 
{ 
  switch (fdwCtrlType) 
  { 
    case CTRL_C_EVENT: 
	case CTRL_BREAK_EVENT: 
	case CTRL_CLOSE_EVENT: 
	  printf("\nUser abort detected! Qcmbr is exiting now!\n");
	  CloseAll();
      return(FALSE);
    default: 
      return FALSE; 
  } 
} 
#endif


int main(int narg, char *arg[]) 
{
    int iarg;
    int console;
    int instance=0;
    int pcie=0;
    extern int setPcie(int Pcie);
    FILE *lf;
    int port;

#ifdef _WINDOWS
	SetConsoleCtrlHandler((PHANDLER_ROUTINE) CtrlHandler, TRUE); 
#endif

    console=0;
    port = -1;

    for(iarg=1; iarg<narg; iarg++)
    {
        if (strcmp(arg[iarg],"-q") == 0)
        {
           gFromQ = 1;
		   printf("Called from QDart.\n");
        } else
        if ( strncmp(arg[iarg], "-port", sizeof( "-port" ) ) == 0)
        {
            if(iarg+1<narg)
            {
                sscanf( arg[iarg+1], " %d ",(int) &port);
                iarg++;
            }
        }
        else if ( strncmp(arg[iarg], "-console", sizeof( "-console" ) ) == 0)
		{
			console=1;
		}
		else if ( strncmp(arg[iarg], "-instance", sizeof( "-instance" ) ) == 0)
		{
			if(iarg<narg-1)
			{
				iarg++;
				sscanf( arg[iarg]," %d ",(int)&instance);
			}
			else
			{
				printf( "Error - NULL instance.\n" );
			}
		}
		else if ( strncmp(arg[iarg], "-log", sizeof( "-log" ) ) == 0)
		{            
			if(iarg<narg-1)
			{
				iarg++;
				lf=fopen(arg[iarg],"a+");
				if(lf==0)
				{
					printf( "Can't open log file %s.\n", arg[iarg] );
				}
				else
				{
					fprintf( lf, "File %s\n", arg[iarg] );
				}			
            		}
			else
			{
				printf( "Error - No log file specified.\n" );
			}
		}
		else if ( strncmp(arg[iarg],"-pcie", sizeof( "-pcie" ) ) == 0)
		{
			if(iarg+1<narg)
			{
				sscanf( arg[iarg+1], " %d ",(int) &pcie);
				iarg++;
			}
			setPcie(pcie);
		}
		else if ( strncmp(arg[iarg],"-help", sizeof( "-help" ) ) == 0)
		{
			printf( "-console" );
			printf( "-log [log file name]" );
			printf( "-port [port number]" );
			printf( "-instance [device index]" );
			exit(0);
		}
		else
		{
			printf( "Error - Unknown parameter \"%[^\"]\"." );
		}
	}

#ifdef _WINDOWS
    if ((ghMutex = CreateMutex(NULL,TRUE,"Qcmbr-Mutex") ) == NULL) {
		if (gFromQ)
		  exit(-2);
	} else
	if (GetLastError() == ERROR_ALREADY_EXISTS) {
		if (gFromQ)
		  exit(-3);
	}
#endif
    
    if(instance == 0)
	{
		if(port<0)
		{
			port=2390;
		} 
	}
    else if(instance == 1)
	{
		if(port<0)
		{
#ifndef __APPLE__	
			port=2391;
#else
			port=2390;
#endif			
		}
    }
    else
    {
#ifndef __APPLE__	
        printf("Only instance 0 and 1 are supported\n");
		exit(1);
#else
		if(port<0)
		{
			port=2390;
		} 	
#endif	
    }
#ifdef _WINDOWS
	if (probe_device() != ERROR_SUCCESS) {
		printf("\nWait for device to be inserted, ^C terminate Qcmbr!\n");
	}
#endif
	Qcmbr_Run(port);
	exit(0);
}

static struct _Socket *_ListenSocket;	// this is the socket on which we listen for client connections

static struct _Socket *_ClientSocket[MCLIENT];	// these are the client sockets


#define MCOMMAND 50

static int _CommandNext=0;		// index of next command to perform
static int _CommandRead=0;		// index of slot for next command read from socket

static char *_Command[MCOMMAND];
static char _CommandClient[MCOMMAND];

static int ClientAccept()
{
    int it;
    int noblock;
    struct _Socket *TryClientSocket;
    static int OldestClient = 0;

	if(_ListenSocket!=0)
	{
		//
		// If we have no clients, we will block waiting for a client.
		// Otherwise, just check and go on.
		//
		noblock=0;
		for(it=0; it<MCLIENT; it++)
		{
			if(_ClientSocket[it]!=0)
			{
				noblock=1;
				break;
			}
		}
		if(noblock==0)
		{
			printf("\nReady for Client(QDart) Connection!" );
		}
		//
		// Look for new client
		//
		for(it=0; it<MCLIENT; it++)
		{
			if(_ClientSocket[it]==0)
			{
				_ClientSocket[it]=SocketAccept(_ListenSocket,noblock);// don't block
				if(_ClientSocket[it]!=0)
				{
					printf("Client connection is established at [%d]!\n",it);
					return it;
				}
			}
		}
        // In case all clients have been used up, but there is another client want to connect, give away the oldest one
        if (it == MCLIENT)
        {
            TryClientSocket = SocketAccept(_ListenSocket,noblock);
            if (TryClientSocket)
            {
                SocketClose(_ClientSocket[OldestClient]);
                _ClientSocket[OldestClient] = TryClientSocket;
                
                return it;
            }
        }
	}
	return -1;
}


static void ClientClose(int client)
{
	if(client>=0 && client<MCLIENT && _ClientSocket[client]!=0)
	{
		SocketClose(_ClientSocket[client]);
		_ClientSocket[client]=0;
	}
}

int CommandRead()
{
	unsigned char buffer[MBUFFER];
	int nread;
	//int ntotal;
	int it;
    int diagPacketReceived = 0;
    unsigned int cmdLen = 0;

	//
	// look for new clients
	//
	ClientAccept();
	//
	// try to read everything on the client socket
	//
	//ntotal=0;
	while(_CommandNext!=_CommandRead || _Command[_CommandRead]==0)
	{
		if(_ListenSocket==0)
		{
		}
		else
		{
			//
			// read commands from each client in turn
			//
			for(it=0; it<MCLIENT; it++)
			{
				if(_ClientSocket[it]!=0)
				{
					nread = (int)SocketRead(_ClientSocket[it],buffer,MBUFFER-1);
					if(nread>0)
					{
						printf( "SocketRead() return %d bytes\n", nread );
						buffer[nread]=0;
                        DispHexString(buffer,nread);
						
						if(nread>1 && buffer[nread-1]==DIAG_TERM_CHAR)
						{
							diagPacketReceived = 1;
							buffer[nread-1]=0;
							cmdLen = nread-0;
 						}
						//Needed for linux path
						if(nread>2 && buffer[nread-2]==DIAG_TERM_CHAR)
						{
							diagPacketReceived = 1;
							buffer[nread-2]=0;
							cmdLen = nread - 1;
						}
						//
						// check to see if we received a diag packet
						//
						if(diagPacketReceived) {
							if(processDiagPacket(it,(unsigned char *)buffer,cmdLen)) {
								printf( "\n--processDiagPacket-succeed------ Wait For Next Diag Packet ----------------\n\n" );
								continue;
							}
							else
							{
								printf( "\n--processDiagPacket-failed------- Wait For Next Diag Packet ----------------\n\n" );
							}
						}
					}
					else if(nread<0)
					{
						printf("Closing connection <-- Remote connection closed.[%d]\n",gFromQ);
						ClientClose(it);
#ifdef _WINDOWS
						CloseAll();
						if (gFromQ == 0)
						  ReLaunch();
#endif
						exit(1);
					}
				}
			}
		}
	}
	return 0; //ntotal;
}


int CommandNext(unsigned char *command, int max, int *client)
{
	int length;
    //
	// try to read new commands
	//
	if(CommandRead()<0)
	{
		return -1;
	}
	//
	// if we have a command, return it
	//
	if(_Command[_CommandNext]!=0)
	{
		length = sizeof( _Command[_CommandNext]); //length=Slength(_Command[_CommandNext]);
		if(length>max)
		{
			_Command[_CommandNext][max]=0;
			length=max;
		}

		if ( command != NULL )
		{
			if ( _Command[_CommandNext] == NULL )
			{
				strncpy( (char*) command,_Command[_CommandNext], 
						( sizeof( command ) > sizeof( _Command[_CommandNext] ) ) ? 
								sizeof( _Command[_CommandNext] ) : ( sizeof( command ) ) );
			}
		}
		*client=_CommandClient[_CommandNext];
		if ( _Command[_CommandNext] != NULL ) { free( _Command[_CommandNext] ); }
		_Command[_CommandNext]=0;
		_CommandNext=(_CommandNext+1)%MCOMMAND;

		printf("> %s\n",command);

		return length;
	}
	return 0;
}

int SendItDiag(int client, unsigned char *buffer, int length)
{
	int nwrite;

	if(_ListenSocket==0|| (client>=0 && client<MCLIENT && _ClientSocket[client]!=0))
	{
		if ( _ListenSocket == 0 )
		{
			//printf("%s",response);
		}
		else
		{
			SocketWriteEnableMode( 1 );
			nwrite=SocketWrite(_ClientSocket[client],buffer,length);
			SocketWriteEnableMode( 0 );
			
			if(nwrite<0)
			{
				printf( "Error - Call to SocketWrite() failed.\n" );
				ClientClose(client);
				return -1;
			}	
		}
	    return 0;
	}
	else
	{
		return -1;
	}

}


void Qcmbr_Run(int port)
{
	unsigned char buffer[MBUFFER];
	int nread;
	int client;
	int it;

	SetStrTerminationChar( DIAG_TERM_CHAR );
	SocketWriteEnableMode( 0 );

    //
    // open listen socket
    //
	if(port>0)
	{
		_ListenSocket=SocketListen(port);
		if(_ListenSocket==0)
		{
			printf( "Can't open control process listen port %d.", port );
			exit(-1);
		}
	}
	else
	{
		//
		// this means accept commands from the keyboard
		// and display result by typing in the console window
		//
		_ListenSocket= 0;
	}

	// Clear the client socket records
	for ( it=0; it < MCLIENT; it++ )
	{
		_ClientSocket[it] = 0;
	}

    //
    // wait for commands or new clients
    //
	//while(1)
	//{
		ClientAccept();

	    while(1)
		{
			nread=CommandNext(buffer,MBUFFER-1,&client);

			//
			// Got data. Process it.
			//
		    if(nread>0)
			{
				// PASS TO DIAG PACKET HANDLER
				processDiagPacket( 0, buffer, nread);
			}
			//
			// Got error. Probably lost command module. Redo socket accept.
			//
			else if(nread<0)
			{
			}
			//
			// slow down
			//
			else
			{
				Sleep(50);
			}
		}
	//}
}
