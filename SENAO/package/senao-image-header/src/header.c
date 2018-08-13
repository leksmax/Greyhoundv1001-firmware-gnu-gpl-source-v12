/*****************************************************************************
;
;   (C) Unpublished Work of Senao Networks, Inc.  All Rights Reserved.
;
;       THIS WORK IS AN UNPUBLISHED WORK AND CONTAINS CONFIDENTIAL,
;       PROPRIETARY AND TRADESECRET INFORMATION OF SENAO INCORPORATED.
;       ACCESS TO THIS WORK IS RESTRICTED TO (I) SENAO EMPLOYEES WHO HAVE A
;       NEED TO KNOW TO PERFORM TASKS WITHIN THE SCOPE OF THEIR ASSIGNMENTS
;       AND (II) ENTITIES OTHER THAN SENAO WHO HAVE ENTERED INTO APPROPRIATE
;       LICENSE AGREEMENTS.  NO PART OF THIS WORK MAY BE USED, PRACTICED,
;       PERFORMED, COPIED, DISTRIBUTED, REVISED, MODIFIED, TRANSLATED,
;       ABBRIDGED, CONDENSED, EXPANDED, COLLECTED, COMPILED, LINKED, RECAST,
;       TRANSFORMED OR ADAPTED WITHOUT THE PRIOR WRITTEN CONSENT OF SENAO.
;       ANY USE OR EXPLOITATION OF THIS WORK WITHOUT AUTHORIZATION COULD
;       SUBJECT THE PERPERTRATOR TO CRIMINAL AND CIVIL LIABILITY.
;
;------------------------------------------------------------------------------
;
;    Project : 
;    Creator : 
;    File    : header.c
;    Abstract: generate MD5 and recovery file for firmware upgrade
;
;       Modification History:
;       By              Date     Ver.   Modification Description
;       --------------- -------- -----  --------------------------------------
;       Mark Lin 2006/0608
;*****************************************************************************/


/*-------------------------------------------------------------------------*/
/*                        INCLUDE HEADER FILES                             */
/*-------------------------------------------------------------------------*/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>    // getopt() ; ftruncate()
#include <sys/stat.h>
#include <netinet/in.h>
#include <img_header.h>
#include <firmwareconfig.h>


/*-------------------------------------------------------------------------*/
/*                           DEFINITIONS                                   */
/*-------------------------------------------------------------------------*/
#define HTONL(x) do {x=htonl(x);} while(0);
#define NTOHL(x) do {x=ntohl(x);} while(0);

/*-------------------------------------------------------------------------*/
/*                           Parameter                                     */
/*-------------------------------------------------------------------------*/

static T_INT32 t_count;

static fwtype FirmwareType[] = 
{
	{BOOT_LOADER_TYPE,        "bootloader"},
	{KERNEL_TYPE,             "kernel"},
	{KNLAPPS_TYPE,            "kernelapp"},
	{APPS_TYPE,               "apps"},
	{APPS_LITTLE_TYPE,        "littleapps"},
	{SOUNDS_TYPE,             "sounds"},
	{FACTORY_APP_DATA_TYPE,   "factoryapps"},
	{USER_CONFIG_TYPE,        "userconfig"},
	{ODM_APP_TYPE,            "odmapps"},
	{LANG_PACK_TYPE,          "langpack"},
	{CUST_LOGO_TYPE,          "cust_logo"},
};
/*****************************************************************
* NAME: usage
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
static void usage(T_INT32 rc)
{
#if !TARGET
	printf("usage: head [-h?] "
		   "\t-h\t\tthis help\n"
		   "\t-s\t\tSource file\n"
		   "\t-d\t\tDestination file\n"
		   "\t-a\t\tAuto set parameter\n"
		   "\t-t\t\tType : \n"
		   "\t\t\t        bootloader \n"
		   "\t\t\t        kernel     \n"
		   "\t\t\t        kernelapp  \n"
		   "\t\t\t        apps       \n"
		   "\t\t\t        factoryapps :factory app\n"
		   "\t\t\t        littleapps :backup application\n"
		   "\t\t\t        appdata    :application data\n"
		   "\t\t\t        userconfig :configuration data\n"
		   "\t\t\t        odmapps       \n"
		   "\t\t\t        langpack       \n"
		   "\t-v\t\tVersion\n"
		   "\t-x\t\tRecovery MD5 file [-u Magickey]\n"
		   "\t-r\t\tVendor ID\n"
		   "\t-p\t\tProduct ID\n"
#if !TARGET
		   "\t-z\t\tZero Padding [-z combined file]\n"
#endif		   
		   "\t-m\t\tMagic Key(32 bits)\n");
#endif
	exit(rc);
}
/*****************************************************************
* NAME: hIsFileExisted
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
static T_BOOL hIsFileExisted(const T_CHAR *filename)
{
	int rval;

	// Check file existence.
	rval = access(filename, F_OK);

	return rval ? FALSE : TRUE;
}
/*****************************************************************
* NAME: hGetFileSize
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
static T_UINT32 hGetFileSize(const T_CHAR *filename)
{
	FILE *fp;
	T_UINT32 fileSize=0;

	if(!hIsFileExisted(filename))
	{
		printf("%s:Open file(%s) error, existed\n", __FUNCTION__, filename);
		return 0;
	}

	fp = fopen(filename, "r");

	if(!fp)
	{
		printf("%s:Open file(%s) error\n", __FUNCTION__, filename);
		return 0;
	}

	fseek(fp, 0, SEEK_END);
	fileSize=ftell(fp);

	fclose(fp);

	return fileSize;
}
/*****************************************************************
* NAME: hCHKSUM
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
static T_INT32 hCHKSUM(T_CHAR *pBuf, T_INT32 len)
{
	T_INT32 i;
	T_INT32 sum=0;

    //protect
	if(pBuf==0 || len<0)
	{
		printf("%s input params error!\n", __FUNCTION__);
		return -1;
	}

	for(i=0;i<len;i++)
	{
		sum += (T_INT32)(pBuf[i]);
	}

	return sum;
}
/*****************************************************************
* NAME: encodeImage
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
T_BOOL encodeImage(T_CHAR *srcFile,T_CHAR *dstFile, imageHeader_t *headerInfo)
{
	FILE *fpSrc;
	FILE *fpDst;
	T_UINT32 fsize_count;
	T_UCHAR *hash_value;
	T_INT32 seekPointSrc=0;
	T_INT32 seekPointDst=0;
	T_INT32 i;
	T_CHAR buf[DATA_BUFFER_SIZE];
	T_CHAR  ch;
	T_UINT32    magickey;

	if((fpSrc=fopen(srcFile, "r+b")) == NULL)
	{
		printf("%s: Cannot open %s !!\n", __FUNCTION__, srcFile);
		return -1;
	}

	if((fpDst=fopen(dstFile, "w+b")) == NULL)
	{
		printf("%s: Cannot open %s !!\n", __FUNCTION__, dstFile);
		fclose(fpSrc);
		return -1;
	}

	/*********** PROCESS the HEADER ***************/
	if((fsize_count=hGetFileSize(srcFile))<=0)
	{
		printf("%s:file open/size error!\n", __FUNCTION__);
	}

	/* store the file len */
	headerInfo->comp_file_len=fsize_count;

	/* calculate the MD5Sum for source file */
	hash_value =  hHash_file(srcFile,1);
	memcpy(headerInfo->md5, hash_value, 16);

	/* set the header check sum to Zero before we calcuate it*/
	headerInfo->comp_file_sum=0;

	/* calcuate the Header Check Sum*/
	headerInfo->header_sum=hCHKSUM((T_CHAR*)headerInfo,sizeof(imageHeader_t));

#if 0
	printf("====before HTONL== Header info ====\n");
	printf("vendor id: %lx\n",headerInfo->vendor_id);
	printf("product id: %lx\n",headerInfo->product_id);
	printf("version id: %s\n",headerInfo->version);
	printf("type: %lx\n",headerInfo->type);
	printf("comp_file_len:%ld\n", headerInfo->comp_file_len);
	printf("comp_file_sum: 0x%lx\n",headerInfo->comp_file_sum);
	printf("Header sum:0x%lx\n",headerInfo->header_sum);
	printf("magic_key: 0x%lx\n",headerInfo->magic_key);
	printf("MD5 chksum: ");
	for(i=0;i<16;i++)
	{
		printf("%x",(headerInfo->md5[i]&0xff));
	}
	printf("\n");
#endif

	/* change the intergers into netowrk formats */
	HTONL(headerInfo->start);
	HTONL(headerInfo->vendor_id);
	HTONL(headerInfo->product_id);
	HTONL(headerInfo->type);
	HTONL(headerInfo->comp_file_len);
	HTONL(headerInfo->comp_file_sum);
	HTONL(headerInfo->comp_file_sum);
	HTONL(headerInfo->header_sum);
	magickey=headerInfo->magic_key;
	HTONL(headerInfo->magic_key);

#if 0
	printf("====after HTONL== Header info ====\n");
	printf("vendor id: %lx\n",headerInfo->vendor_id);
	printf("product id: %lx\n",headerInfo->product_id);
	printf("version id: %s\n",headerInfo->version);
	printf("type: %lx\n",headerInfo->type);
	printf("comp_file_len:%ld\n", headerInfo->comp_file_len);
	printf("comp_file_sum: 0x%lx\n",headerInfo->comp_file_sum);
	printf("Header sum:0x%lx\n",headerInfo->header_sum);
	printf("magic_key: 0x%lx\n",headerInfo->magic_key);
	printf("MD5 chksum: ");
	for(i=0;i<16;i++)
	{
		printf("%x",(headerInfo->md5[i]&0xff));
	}
	printf("\n");
#endif

	/* write the header to dst file */
	fwrite(headerInfo,sizeof(*headerInfo), 1, fpDst);
	/* adjust the seek point for dst file*/
	seekPointDst+=sizeof(*headerInfo);


	/*********** PROCESS the IMAGE (DATA) ***************/

	/* write the src file to dst file, XOR bytes before write */
	while(!(fsize_count == 0))
	{
		/* process the last few bytes */
		if(fsize_count < DATA_BUFFER_SIZE)
		{
			for(i=0;i<fsize_count;i++)
			{
				fseek(fpSrc,seekPointSrc+i,SEEK_SET); 
				fread ((T_CHAR*)&ch,1,1, fpSrc);
				/* 'source file' xor 'magickey' */
				ch = ch ^ (T_CHAR)(((magickey >> (i%8)) & 0xff));
				fseek(fpSrc,seekPointDst+i,SEEK_SET); 
				fwrite((T_CHAR*)&ch,1,1, fpDst);
			}

			fsize_count = 0; // break while loop  
		}
		else
		{
			/*speed write, write in blocks */
			fseek(fpSrc,seekPointSrc,SEEK_SET); 
			fread (buf, DATA_BUFFER_SIZE,1, fpSrc);

			fsize_count -= DATA_BUFFER_SIZE ;

			for(i=0;i<DATA_BUFFER_SIZE;i++)
			{
				/* 'source file' xor 'magickey' */
				buf[i] = buf[i] ^ (T_CHAR)(((magickey >> (i%8)) &0xff)) ;
			}

			fseek(fpDst,seekPointDst, SEEK_SET); 
			fwrite(buf, DATA_BUFFER_SIZE,1, fpDst);

			seekPointSrc += DATA_BUFFER_SIZE;
			seekPointDst += DATA_BUFFER_SIZE;
		}
	}

	if(fpSrc) fclose(fpSrc);
	if(fpDst) fclose(fpDst);

	return 1; 
}

/*****************************************************************
* NAME: decodeImage
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
T_BOOL decodeImage(T_CHAR *filename,T_UINT32 magickey,T_UINT32 type, T_UINT32 vid, T_UINT32 pid)
{
	FILE     *fpSrc;
	T_CHAR   buf_temp[255] = {0};
    T_CHAR   new_filename[255] = {0};
    T_CHAR   md5ChkSum[16];
	T_CHAR   ch;
	T_UINT32 fsize_count, fsize;
	T_INT32  seekPointSrc = 0;
	T_INT32  seekPointDst = 0;
    T_INT32  md5_fail = 0;
	T_UCHAR  *hash_value;
	T_CHAR   buf[DATA_BUFFER_SIZE];
	T_INT32  i;
	imageHeader_t header;

	// Get file size
    fsize_count=hGetFileSize(filename);

    // protect
	if(fsize_count <= 0)
	{
		printf("%s:file open/size error!\n", __FUNCTION__);
		return -1;        
	}

	fsize_count = fsize_count - sizeof(imageHeader_t);
	fsize = fsize_count ;

    // protect
	if((fsize_count == 0) || (fsize_count >= MAX_CODE_SIZE) || (fsize_count < sizeof(imageHeader_t)))
	{
		printf("fsize %u is incorrect \n", fsize);
		return -1;
	}

    if((fpSrc=fopen(filename, "r+w+b")) == NULL)
    {
        printf("Cannot fopen %s !!\n", filename);
        return -1;
    }

	fseek(fpSrc, 0L, SEEK_SET);

	/* get the header of the source file (96 bytes)*/
	for(i=0; i<sizeof(imageHeader_t); i++)
	{
		fread ((T_CHAR*)&ch, 1, 1, fpSrc); 
		buf_temp[i] = ch; 
	}

	/* check header's message : type , product ID , version , vendor ID */

	/* copy src_file's herader information to header struct */
	memcpy(&header,buf_temp, sizeof(imageHeader_t));

	/* convert the network byte orders into host byte orders */ 
	NTOHL(header.start);
	NTOHL(header.vendor_id);
	NTOHL(header.product_id);
	NTOHL(header.type);
	NTOHL(header.comp_file_len);
	NTOHL(header.comp_file_sum);
	NTOHL(header.comp_file_sum);
	NTOHL(header.header_sum);
	NTOHL(header.magic_key);
	//NTOHL(magickey);
#if 0 // debug
	printf("~~~~~~~~~~~ > magickey 0x%x\n",magickey);

	printf("==== your Header info ====\n");
	printf("vendor id: %x\n",header.vendor_id);
	printf("product id: %x\n",header.product_id);
	printf("version id: %s\n",header.version);
	printf("type: %x\n",header.type);
	printf("comp_file_len:%d\n", header.comp_file_len);
	printf("fsize:0x%x\n", fsize  );
	printf("comp_file_sum: 0x%x\n",header.comp_file_sum);
	printf("Header sum:0x%x\n",header.header_sum);
	printf("magic_key: 0x%x\n",header.magic_key);
	printf("MD5 chksum: ");
	for(i=0;i<16;i++)
	{
		printf("%x ",(header.md5[i]&0xff));
	}
	printf("\n");
#endif

	/* 20131020 Jason: Check header product ID and version ID */
	if(vid !=0 && pid !=0) //User input -r -p
	{
		if((header.vendor_id != vid) || (header.product_id != pid))
		{
			printf("Firmware pid or vid error! It should be 0x%.4x%.4x\n", header.vendor_id, header.product_id);
			fclose(fpSrc);
			return -1;
		}
	}

	/* if -t(t_count=1) then check firmware type */
	if(t_count)
	{
		/* check firmware type */
		if(header.type != type)
		{
			printf("firmware type is not correct. Header type: %d, expected type %d \n", header.type, type);
			fclose(fpSrc);
			return -1;
		}
	}

	/* Recovery XOR Source file and shift 96 bytes */
	seekPointSrc = sizeof(imageHeader_t);

	while(fsize_count > 0)
	{
		if(fsize_count < DATA_BUFFER_SIZE)
		{
			for(i=0;i<fsize_count;i++)
			{
				fseek(fpSrc,seekPointSrc+i,SEEK_SET); 
				fread ((T_CHAR*)&ch,1,1, fpSrc);

				/* 'source file' xor 'magickey' */
				ch = ch ^ (T_CHAR)(((magickey >> (i%8)) & 0xff));
				//printf("0x%x ",(T_CHAR)(((magickey >> (i%8)) & 0xff)));

				fseek(fpSrc,seekPointDst+i,SEEK_SET); 
				fwrite((T_CHAR*)&ch,1,1, fpSrc);
			}
			//printf("\n");
			fsize_count = 0; // break while loop  
		}
		else
		{
			fseek(fpSrc,seekPointSrc,SEEK_SET); 
			fread (buf, DATA_BUFFER_SIZE,1, fpSrc);

			fsize_count -= DATA_BUFFER_SIZE ;

			/* XOR */
			for(i=0;i<DATA_BUFFER_SIZE;i++)
			{
				/* 'source file' xor 'magickey' */
				buf[i] = buf[i] ^ (unsigned char)(((magickey >> (i%8)) & 0xff)) ;
			}

			fseek(fpSrc,seekPointDst, SEEK_SET); 
			fwrite(buf, DATA_BUFFER_SIZE,1, fpSrc);

			seekPointSrc += DATA_BUFFER_SIZE;
			seekPointDst += DATA_BUFFER_SIZE;
		}
	}

	/* truncate tail(96 bytes) ; ftruncate(file handle number , size) */
	if(ftruncate(fileno(fpSrc),fsize) < 0 )
	{
		printf("Error: Unable to truncate file(%s) \n",filename);
		fclose(fpSrc);
		return -1;
	}

	fclose(fpSrc); // close source file first
#if 0
	/* add ".bin" at the end of the file name */
	strcpy(new_filename, filename);
	strcat(new_filename, ".bin");
	if(rename(filename, new_filename) < 0 )
	{
		printf("Error: Unable to rename file(%s)->(%s) \n",filename, new_filename);
		return -1;
	}
#endif

	/* -----Get file size ----- */
	if((fsize=hGetFileSize(filename))<=0)
	{
		printf("%s:file open/size error!\n", __FUNCTION__);
		return -1;        
	}

	/* get the MD5 checksum of the src_file */


	/* calculate the MD5Sum for source file */
	hash_value =  hHash_file(filename,1);
	/* copy MD5sum to array */
	memcpy(md5ChkSum,hash_value,16);

	//printf("md5header =");for (i=0;i<16;i++) { printf("0x%x", header.md5[i]&0xff);} printf("\n");

	//printf("md5 =");for (i=0;i<16;i++) { printf("0x%x", md5ChkSum[i]&0xff);} printf("\n");

	for(i=0;i<16;i++)
	{
		if(md5ChkSum[i] != header.md5[i] )
		{
			md5_fail ++;
//  		printf("md5ChkSum[%d]=%x header.md5[%d]=%x \n",i,md5ChkSum[i],i,header.md5[i]);
		}
	}

	if(md5_fail > 0)
	{
		/*remove incorrect file*/
		remove(filename);
		printf("Checksum check failed!\n");
		//printf("Remove file: %s \n",filename);
		return -1;
	}

	return 1; 
}
/*****************************************************************
* NAME: main
* ---------------------------------------------------------------
* FUNCTION: 
* INPUT:    
* OUTPUT:   
* Author:   
* Modify:   
****************************************************************/
T_INT32 main(T_INT32 argc, char *argv[])
{
	T_CHAR   *src_file=NULL,*dest_file=NULL,*u_file=NULL;
	T_INT32  s_count=0,d_count=0,v_count=0,r_count=0,p_count=0,a_count=0;
	T_INT32  generate_magic_key=0;
	T_UINT32 pos,i;
	// recovery_code = 0 : generate header + XOR Source file and compute MD5 checksum
	// recovery_code = 1 : check MD5sum and take of header and recovery XoR's file
	T_INT32    recovery_code =0 ;
	T_UINT32   VendorId=0;
	T_UINT32   ProductId=0;
	T_UINT32   FileType=0;
	T_CHAR     *FwType=NULL;
	T_CHAR     *Version=NULL;
	T_UINT32   magickey=0;
#if !TARGET
	T_UINT32   block_size=65536;	/*default value is 64K*/
	T_UINT32   extra_zero_padding_size=0;	/*default value is 0*/
	T_INT32    zero_padding = 0;
	T_CHAR     *combined_file=NULL;
#endif	
	//T_UINT32   temp=0x12345678;

	t_count=0;
	while((pos = getopt(argc, argv, ":s:d:t:v:r:p:m:x:h?:alz:c:b:")) != EOF)
	{
		switch(pos)
		{
		case 's':
			src_file = optarg;
			s_count = 1;
			break;
		case 'd':
			dest_file = optarg;  
			d_count = 1;          
			break;  
		case 'a':
			a_count = 1;     
			magickey = MAGIC_KEY;  
			break;         
		case 't':
			// FileType = strtol(optarg, NULL,10);
			FwType = optarg;
			t_count = 1;
			break;
		case 'v':
			Version = optarg;
			v_count = 1;
			break;
		case 'r':
			VendorId = strtol(optarg, (char **)NULL,16);
			r_count = 1;
			break;
		case 'p':
			ProductId = strtol(optarg, (char **)NULL,16);
			p_count = 1;
			break;
		case 'm':
			magickey = strtoul(optarg, (char **)NULL,16);
			magickey = (magickey);
			generate_magic_key = 1;
			break;
		case 'x':
			u_file = optarg;  
			magickey = MAGIC_KEY;
			recovery_code = 1;
			break;
#if !TARGET
		case 'z':
			zero_padding = 1;
			extra_zero_padding_size = strtol(optarg, (char **)NULL,10);
			break;
		case 'c':
			combined_file = optarg;
			break;
		case 'b':
			block_size = strtol(optarg, (char **)NULL,10);
			break;
#endif			
        case 'h':
            /* fall through */
		case '?':
			usage(0);
			return 0;

		default:
			usage(1);
			return 1;
		}
	}

	if(!recovery_code &(!s_count || !d_count))
	{
		usage(1);
		return -1;
	}

	if( a_count == 1)
	{
		if((v_count == 1) || (r_count == 1) || (p_count == 1) || (generate_magic_key == 1))
			usage(0);
	}


	if(t_count)
	{
		/* check firmware type */
		for(i=0;i<(sizeof(FirmwareType)/sizeof(FirmwareType[0]));i++)
		{
			if(!(strcmp(FirmwareType[i].fwmethod,FwType)))
			{
				FileType= FirmwareType[i].type ;
				goto CorrectFwType;
			}
		}
		usage(0);   
	}

CorrectFwType:

	if(recovery_code == 0)
	{
		imageHeader_t headerInfo;

#if !TARGET
		if(zero_padding)
		{
			if(src_file)
			{
				int zeroCnt = 0;
				int srcSize = hGetFileSize(src_file);
				char cmdBuff[256];
				FILE *fp;

				zeroCnt = block_size - (srcSize%block_size) + extra_zero_padding_size;

				if(zeroCnt == block_size)
				{
					zeroCnt = 0;
				}

				printf("srcSize 0X%x\n", srcSize);
				printf("zeroCnt 0X%x\n", zeroCnt);
				printf("blocksize 0X%x\n", block_size);

				fp = fopen(src_file, "a+");

				if(fp)
				{
					for(i = 0; i < zeroCnt; ++i)
					{
						fputc('\0', fp);
					}
					fclose(fp);
				}
				printf("Padded Size   --> 0X%x\n", hGetFileSize(src_file));

				if(combined_file)
				{
					sprintf(cmdBuff, "cat %s >> %s", combined_file, src_file);
					system(cmdBuff);
	
					printf("Combined Size --> 0X%x\n", hGetFileSize(src_file));
				}
			}
		}
#endif
		if(a_count == 1)
		{
			headerInfo.start=0;
			headerInfo.vendor_id=VENDOR_ID;
			headerInfo.product_id=PRODUCT_ID;
			headerInfo.type=FileType;
			headerInfo.magic_key=MAGIC_KEY;
			strncpy(headerInfo.version, VERSION,16);
		}
		else
		{
			headerInfo.start=0;
			headerInfo.vendor_id=VendorId;
			headerInfo.product_id=ProductId;
			headerInfo.type=FileType;
			headerInfo.magic_key=magickey;
			strncpy(headerInfo.version, Version,16);
		}
		encodeImage(src_file,dest_file, &headerInfo);
	}
	else
	{
		if(decodeImage(u_file, magickey,FileType, VendorId, ProductId)!=1)
		{
			return -1;
		}
	}

	// Check print, be used at other APPs
	fprintf(stdout, "header: Return OK\n");

	return 1;
}






