#define WLAN_5G_LED			68
#define WLAN_2G_LED			67
#define USB1_LED			7
#define USB2_LED			12
#define WPS1_LED			13
#define SD1_LED				24
#define POWER_LED			53

#define WPS_2G_BTN			65
#define WPS_5G_BTN			26
#define RESET_BTN			54
#define POWER_HW_BTN			17

#define RESET_PIN			16
#define PCIE_INIT			15
#define PCIE1_RESET			3
#define PCIE1_WAKE			4
#define PCIE1_CLOCK			5
#define PCIE2_RESET			64
#define PCIE2_WAKE			49
#define PCIE2_CLOCK			50
#define PCIE3_RESET			NULL
#define PCIE3_WAKE			NULL
#define PCIE3_CLOCK			NULL
#define I2C_DATA			8
#define I2C_CLOCK			9
#define SD_VOLT_SWITCH			22
#define SD_DETECT			25
#define SPDIF_CFG			48
#define WTD_INT				6
#define WTD_EN				23

#define UART_TX				10
#define UART_RX				11
#define I2S_MOSI			55
#define I2S_MISO			56
#define I2S_CS				57
#define I2S_CLK				58
#define QFPROM_EN			66
#define BOOT_TCXO			33
#define BOOT_MOSI			18
#define BOOT_MISO			19
#define BOOT_CS				20
#define BOOT_CLK			21
#define RGMII_TX_CLK			27
#define RGMII_TX_3			28
#define RGMII_TX_2			29
#define RGMII_TX_1			30
#define RGMII_TX_0			31
#define RGMII_TX_CTL			32
#define RGMII_RX_CLK			51
#define RGMII_RX_3			52
#define RGMII_RX_2			59
#define RGMII_RX_1			60
#define RGMII_RX_0			61
#define RGMII_RX_CTL			62
#define SWITCH_RESET			63

#define WLR9100_GPIO_LED_STATUS_AMBER	POWER_LED
#define WLR9100_GPIO_LED_WPS_WHITE	WPS1_LED

#define WLR9100_GPIO_BTN_WPS		WPS_2G_BTN
#define WLR9100_GPIO_BTN_RFKILL		WPS_5G_BTN

#define WLR9100_KEYS_POLL_INTERVAL    20  /* msecs */
#define WLR9100_KEYS_DEBOUNCE_INTERVAL    (3 * WLR9100_KEYS_POLL_INTERVAL)

#define WLR9100_MAC0_OFFSET       0
#define WLR9100_MAC1_OFFSET       6
#define WLR9100_WMAC_CALDATA_OFFSET   0x1000
#define WLR9100_PCIE_CALDATA_OFFSET   0x5000
