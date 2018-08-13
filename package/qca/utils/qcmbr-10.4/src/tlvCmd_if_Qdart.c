/* 
Copyright (c) 2013 Qualcomm Atheros, Inc.
All Rights Reserved. 
Qualcomm Atheros Confidential and Proprietary. 
*/  

/* tlvCmd_if_Qdart.c - Interface to DevdrvIf.DLL ( DevdrvIf.DLL access device driver ) */

#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/file.h>
#include <sys/ioctl.h>
#include <mtd/mtd-user.h>

#include "Qcmbr.h"
#define CALDATA_SIZE 12500
static char FlashCalData[CALDATA_SIZE];
char CaldataBkUp[CALDATA_SIZE];// For backing up second radio caldata
static int BoardDataSize;
int pcie=0;
int BDCapture=0;

//  Remote error number and error string
A_INT32 remoteMdkErrNo = 0;
A_CHAR remoteMdkErrStr[SIZE_ERROR_BUFFER];

// holds the cmd replies sent over channel
static CMD_REPLY cmdReply;
static A_BOOL cmdInitCalled = FALSE;

/**************************************************************************
* receiveCmdReturn - Callback function for calling cmd_init().
*       Note: We are keeping the calling convention.
*       Note: cmd_init() is a library function from DevdrvIf.DLL.
*		Note: Qcmbr does not ( need to ) do anything to the data or care
*			  what is in the data.
*/
void receiveCmdReturn(void *buf)
{
        printf("CallBack-receiveCmdReturn bufAddr[%8.8X]\n",buf);
	if ( buf == NULL )
	{
	}
	// Dummy call back function
}

/**************************************************************************
* artSendCmd2 - This function sends the TLV command passing from host (caller)
*				to the device interface function.
*				
*/

A_BOOL artSendCmd2( A_UINT8 *pCmdStruct, A_UINT32 cmdSize, unsigned char* responseCharBuf, unsigned int *responseSize )
{
    int		errorNo;
    char buf[2048 + 8];

    extern void receiveCmdReturn1(void *buf);
    extern void DispHexString(A_UINT8 *pCmdStruct,A_UINT32 cmdSize);
    DispHexString(pCmdStruct,cmdSize);

    memset(buf, 0, sizeof(buf));

    if (cmdInitCalled == FALSE)
    {
	    if (pcie==0)
			errorNo = cmd_init("wifi0",receiveCmdReturn1);
	    else if (pcie==1)
			errorNo = cmd_init("wifi1",receiveCmdReturn1);

    	cmdInitCalled = TRUE;
    }

    memcpy(&buf[8],pCmdStruct,cmdSize);

    printf( "arSendCmd2->cmd_send2 RspLen [%d]\n", *responseSize );
    cmd_send2( buf, cmdSize, responseCharBuf, responseSize );

    remoteMdkErrNo = 0;
    errorNo = (A_UINT16) (cmdReply.status & COMMS_ERR_MASK) >> COMMS_ERR_SHIFT;
    if (errorNo == COMMS_ERR_MDK_ERROR)
    {
        remoteMdkErrNo = (cmdReply.status & COMMS_ERR_INFO_MASK) >> COMMS_ERR_INFO_SHIFT;
        strncpy(remoteMdkErrStr,(const char *)cmdReply.cmdBytes,SIZE_ERROR_BUFFER);
	printf("Error: COMMS error MDK error for command DONT_CARE\n" );
        return TRUE;
    }

    // check for a bad status in the command reply
    if (errorNo != CMD_OK)
	{
	printf("Error: Bad return status (%d) in client command DONT_CARE response!\n", errorNo);
        return FALSE;
    }

    return TRUE;
}

int setPcie(int Pcie)
{
    printf("setting pcie to %d\n",Pcie);
    pcie = Pcie;
    return 0;
}
int setBordDataCaptureFlag (int flag)
{
    printf("setting BDCaptureFlag to %d\n",flag);
    BDCapture=flag;
    if (flag==1){
	//clear BoardDataSize
	BoardDataSize=0;
    }
}

#define MAX_EEPROM_SIZE 0x4000
#define FLASH_BASE_CALDATA_OFFSET 0x1000
#define BD_BLOCK_SIZE 256

void flashWrite()
{
       	int fd;
        int offset;
	mtd_info_t mtdInfo;           // MTD structure for NOR flash
	erase_info_t eraseInfo;       // erase block structure for NOR flash
       	
	if((fd = open("/dev/caldata", O_RDWR)) < 0) {
        	perror("Could not open flash. Returning without write\n");
		return;
	}

	// NOR flash needs sector etase before writing into a sector
	if (ioctl(fd, MEMGETINFO, &mtdInfo) == 0){   // get /dev/caldata MTD info; return 0 for NOR flash and -1 for NAND
		// Take backup of other radio
		offset = (1-pcie)*MAX_EEPROM_SIZE+FLASH_BASE_CALDATA_OFFSET;
		lseek(fd, offset, SEEK_SET);
		if (read(fd, CaldataBkUp, sizeof(CaldataBkUp)) < 1) {
			perror("\nread\n");
			printf("Cannot take backup! Cannot complete flash write\n");
			return;
		}
		printf("Erasing NOR flash caldata sector before write...Erase size 0x%x\n",mtdInfo.erasesize);
		// Caldata for all radios reside in first sector.
		eraseInfo.start = 0;
		eraseInfo.length=mtdInfo.erasesize;
		if (ioctl(fd, MEMUNLOCK, &eraseInfo) < 0) {
			printf("Warning:: Not able to Unlock caldata sector. Proceeding anyway\n");
		}
		if (ioctl(fd, MEMERASE, &eraseInfo) < 0) {
			printf("Can not erase /dev/caldata partition. Returning\n");
			return;
		}
		// Write back the backed up caldata for the other radio
		lseek(fd, offset, SEEK_SET);
		if (write(fd, CaldataBkUp, sizeof(CaldataBkUp)) < 1) {
			perror("\nwrite\n");
			printf("Cannot complete flash write\n");
			return;
		}
	}
       	// wifi0-> pcie0-> offset5 0x1000; wifi1-> pcie 1 -> offset 0x5000
	offset=pcie*MAX_EEPROM_SIZE+FLASH_BASE_CALDATA_OFFSET;
       	lseek(fd, offset, SEEK_SET);
      	if (write(fd, FlashCalData, BoardDataSize) < 1) {
         	perror("\nwrite\n");
    		return;
        }
	close(fd);
	printf("Caldata written into Flash successfully @ offset %0x Size %d\n",offset,BoardDataSize);
}

void BoardDataCapture(unsigned char * respdata)
{
   if (BDCapture==0){
	return;
   }else if (BDCapture==1){
	int dataSize=(respdata[105]<<8) + respdata[104];
	BoardDataSize+=dataSize;
	printf("Capturing Caldata by Qcmbr:: Block number %d Size %d\n",respdata[107],dataSize);
	memcpy(&(FlashCalData[respdata[107]*BD_BLOCK_SIZE]),(unsigned char *)&(respdata[108]), dataSize);
   }
}
