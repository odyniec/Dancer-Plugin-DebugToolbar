var dancer_plugin_debugtoolbar = {
    /* 
     * Save the original values of globally scoped objects that will be
     * overwritten to restore them later
     */
    original: {
        jQuery: window.jQuery,
        $: window.$,
        YAML: window.YAML
    }
};
