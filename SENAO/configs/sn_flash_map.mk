#define ATAG_IPQ_NOR_PARTITION 0x494e4f52 /* INOR */
#define ATAG_MSM_PARTITION 0x4d534D70 /* MSMp */

#define MSM_MTD_MAX_PARTS 16
#define MSM_MAX_PARTITIONS 18

#define SMEM_FLASH_PART_MAGIC1     0x55EE73AA
#define SMEM_FLASH_PART_MAGIC2     0xE35EBDDB
#define SMEM_FLASH_PART_VERSION    0x3

#define SMEM_MAX_PART_NAME         16
#define SMEM_MAX_PARTITIONS        16


#ifdef CONFIG_ARCH_IPQ806X
#define SMEM_LINUX_FS_PARTS					\
	{							\
		"0:SBL1",	"0:MIBIB",	"0:SBL2",	\
		"0:SBL3",	"0:DDRCONFIG",	"0:SSD",	\
		"0:TZ",		"0:RPM",	"0:APPSBL",	\
		"0:APPSBLENV",	"0:ART",	"0:HLOS",	\
		"rootfs",					\
	}
#define SMEM_LINUX_MTD_NAME					\
	{							\
		"SBL1",		"MIBIB",	"SBL2",		\
		"SBL3",		"DDRCONFIG",	"SSD",		\
		"TZ",		"RPM",		"APPSBL",	\
		"APPSBLENV",	"ART",		"kernel",	\
		"rootfs",					\
	}

#else
#define SMEM_LINUX_FS_PARTS	"0:EFS2APPS"
#define SMEM_LINUX_MTD_NAME	"0:EFS2APPS"
#endif
