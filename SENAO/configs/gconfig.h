/**
 *
 * Copyright (C) , SENAO INTERNATIONAL CO., LTD All rights reserved.
 * No part of this document may be reproduced in any form or by any 
 * means or used to make any derivative work (such as translation,
 * transformation, or adaptation) without permission from Senao
 * Corporation.
 */

/*-------------------------------------------------------------------------*/
/*                        Partition Info                                   */
/*-------------------------------------------------------------------------*/
#define BOOTLOADER_PARTITION_NAME           "u-boot"
#define BOOTLOADER_CONFIG_PARTITION_NAME    "u-boot-env"
#define KERNEL_PARTITION_NAME               "kernel"
#define APP_STORAGE_PARTITION_NAME          "rootfs"
#define COMBINED_APP_PARTITION_NAME         "firmware"



/*-------------------------------------------------------------------------*/
/*                       Option Setting Info                               */
/*-------------------------------------------------------------------------*/
#define WIFI_RADIO_NUM  2
#define NTP_SERVER_NUM  3
#define MAC_FILTER_NUM  32
#define DNS_SERVER_NUM  4
#define WDS_MAC_NUM     4
#define MAX_WIFI_CLIENT_NUM  128
/*-------------------------------------------------------------------------*/
/*                       Interface  Info                                   */
/*-------------------------------------------------------------------------*/
#define BRG_DEV         "br-lan"
#define LAN_IF          "eth0"
#define WIFI_24G_IF     "ath0"
#define WIFI_5G_IF      "ath1"
#define WIFI_24G        "wifi0"
#define WIFI_5G         "wifi1"

#define AP_WIFI_IFACE_NUM           8
#define STA_WIFI_IFACE_NUM          1
#define WDSB_WIFI_IFACE_NUM         1
#define WDSAP_AP_WIFI_IFACE_NUM     4
#define WDSAP_WDS_WIFI_IFACE_NUM    1
#define WDSSTA_WIFI_IFACE_NUM       1

#define STA_PROFILE_NUM             3

#define AP_WIFI_24G_IFACE_NO        0   //2.4G: wifi-iface[0] ... wifi-iface[7]
#define AP_WIFI_5G_IFACE_NO         8   //5G: wifi-iface[8] ... wifi-iface[15]
#define WDSB_WIFI_24G_IFACE_NO      16  //2.4G: wifi-iface[16]
#define WDSB_WIFI_5G_IFACE_NO       17  //2.4G: wifi-iface[17]
#define WDSAP_WIFI_24G_WDS_IFACE_NO 18  //2.4G: wifi-iface[18]
#define WDSAP_WIFI_5G_WDS_IFACE_NO  23  //5G: wifi-iface[23]
#define WDSAP_WIFI_24G_IFACE_NO     19  //2.4G: wifi-iface[19] ... wifi-iface[22]
#define WDSAP_WIFI_5G_IFACE_NO      24  //5G: wifi-iface[24] ... wifi-iface[27]
#define WDSSTA_WIFI_24G_IFACE_NO    28  //2.4G: wifi-iface[28]
#define WDSSTA_WIFI_5G_IFACE_NO     29  //2.4G: wifi-iface[29]
#define STA_WIFI_24G_IFACE_NO       30  //2.4G,5G: wifi-iface[30] ...
#define STA_WIFI_5G_IFACE_NO        31  //2.4G,5G: wifi-iface[31] ...

/*
 * Below setting just for rmgmt.
 * char DEFAULT_24G_VAP records  all of 2.4G_VAP. rmgmt will destroy all of 2.4G_VAP except the first one VAP
 * char DEFAULT_5G_VAP  records  all of 5G_VAP.   rmgmt will destroy all of 5G_VAP   except the first one VAP
 * ex: #define DEFAULT_24G_VAP "ath24G-0,ath24G-1,ath24G-2"
*/
#define SEPARATION  ","
#define DEFAULT_24G_VAP "ath0"
#define DEFAULT_5G_VAP  "ath1"

