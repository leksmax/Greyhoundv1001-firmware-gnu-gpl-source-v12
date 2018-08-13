#define ap136_leds_gpio wlr8100_leds_gpio
static struct gpio_led wlr8100_leds_gpio[] __initdata = {
    {
        .name       = "wlr8100:amber:status",
        .gpio       = WLR8100_GPIO_LED_STATUS_AMBER,
        .active_low = 1,
    },
    {
        .name       = "wlr8100:white:wps",
        .gpio       = WLR8100_GPIO_LED_WPS_WHITE,
        .active_low = 1,
    },
    {
        .name       = "wlan-2g",
        .gpio       = WLAN_2G_LED,
        .active_low = 1,
    },
    {
        .name       = "wlan-5g",
        .gpio       = WLAN_5G_LED,
        .active_low = 1,
    },
};

#define ap136_gpio_keys wlr8100_gpio_keys
static struct gpio_keys_button wlr8100_gpio_keys[] __initdata = {
    {
        .desc       = "WPS button",
        .type       = EV_KEY,
        .code       = KEY_WPS_BUTTON,
        .debounce_interval = WLR8100_KEYS_DEBOUNCE_INTERVAL,
        .gpio       = WLR8100_GPIO_BTN_WPS,
        .active_low = 1,
    },
    {
        .desc       = "RFKILL button",
        .type       = EV_KEY,
        .code       = KEY_RFKILL,
        .debounce_interval = WLR8100_KEYS_DEBOUNCE_INTERVAL,
        .gpio       = WLR8100_GPIO_BTN_RFKILL,
        .active_low = 1,
    },
};
