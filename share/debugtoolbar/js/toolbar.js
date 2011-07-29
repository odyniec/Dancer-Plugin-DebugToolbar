dancer_plugin_debugtoolbar.jQuery = jQuery;
dancer_plugin_debugtoolbar.YAML = YAML;

window.jQuery = dancer_plugin_debugtoolbar.original.jQuery;
window.$ = dancer_plugin_debugtoolbar.original.$;
window.YAML = dancer_plugin_debugtoolbar.original.YAML;

dancer_plugin_debugtoolbar.jQuery(document).ready(function ($) {
    function fixWindowHeight() {
        if (windowDisplayed)
            $('.screen', $window).each(function () {
                $(this).css('height', $(window).height() * 0.7 + 'px');
    
                $('.content', $(this)).each(function () {
                    $(this).css('height', $(this).parent().height() -
                            $(this).position().top + 'px');
                });
            });
    }
    
    function display(screen) {
        if ($('.dancer_plugin_debugtoolbar_window').is(':visible')) {
            
        }
        else {
            /* Show the information window */
            
            var top = $('.dancer_plugin_debugtoolbar_toolbar').offset().top - 
                $(window).scrollTop() +
                $('.dancer_plugin_debugtoolbar_toolbar').outerHeight() + 5;
            
            $('.dancer_plugin_debugtoolbar_window').hide();
            $('.dancer_plugin_debugtoolbar_window')
                .css({ left: '5px', right: '5px', top: top + 'px'}).fadeIn(300);
        }
        
        $('.screen:not(.' + screen + ')', $window).hide();
        $('.screen.' + screen, $window).show();
        
        windowDisplayed = true;
        
        fixWindowHeight();
    }
    
    function hide() {
        $('.dancer_plugin_debugtoolbar_window').fadeOut(300);
        windowDisplayed = false;
    }

    var info = $.parseJSON(dancer_plugin_debugtoolbar.info);
    var windowDisplayed = false;

    $('body').append(dancer_plugin_debugtoolbar.html);
    
    $toolbar = $('.dancer_plugin_debugtoolbar_toolbar');
    
    /* Clicking on the logo expands/collapses the toolbar */ 
    $('.logo', $toolbar).click(function () {
        $('.buttons', $toolbar).toggle();
        
        if (!$('.buttons', $toolbar).is(':visible')) {
            if (windowDisplayed)
                hide();
        }
    });
    
    $('.buttons .data', $toolbar).click(function () {
        display('data');    
    });
    
    $('.buttons .routes', $toolbar).click(function () {
        display('routes');
    });
    
    /* Close toolbar */
    $('.dancer_plugin_debugtoolbar_close').click(function () {
        $toolbar.remove();
    });

    /* Left/right toolbar alignment */
    $('.buttons .align_left, .buttons .align_right', $toolbar).live('click',
        function () {
            if ($(this).hasClass('align_left')) {
                $toolbar.css('left', $toolbar.css('right'));
                $toolbar.css('right', 'auto');
                $(this).attr('title', 'Move the toolbar to the right');
            }
            else {
                $toolbar.css('right', $toolbar.css('left'));
                $toolbar.css('left', 'auto');
                $(this).attr('title', 'Move the toolbar to the left');
            }
            
            $(this).toggleClass('align_left align_right');
        });
        
    $('.buttons .time', $toolbar).text(info.time.toFixed(4) + 's');
    
    var $window = $('.dancer_plugin_debugtoolbar_window');
    
    $(window).resize(function () {
        fixWindowHeight();
    });
    
    $('.data .structure.config', $window).html(info.data.config.html);
    $('.data .structure.request', $window).html(info.data.request.html);
    $('.data .structure.session', $window).html(info.data.session.html);
    $('.data .structure.vars', $window).html(info.data.vars.html);
    
    /* Routes */
    
    var html = '';
    for (name in info.routes.all) {
        html += '<h2>' + name + '</h2>';
        for (var i = 0; i < info.routes.all[name].length; i++) {
            html += '<div class="structure">' + info.routes.all[name][i].html +
                '</div>';
        }
    }
    
    $('.routes div.all', $window).html(html);
    
    html = '';
    for (name in info.routes.matching) {
        html += '<h2>' + name + '</h2>';
        for (var i = 0; i < info.routes.matching[name].length; i++) {
            html += '<div class="structure">' +
                info.routes.matching[name][i].html + '</div>';
        }
    }
    
    $('.routes div.matching', $window).html(html);
    
    $('.routes .content > div', $window).hide();
    
    $('.routes ul.tab li', $window).click(function () {
        $('.routes ul.tab li', $window).removeClass('active');
        $('.routes .content > div', $window).hide();
        $('.routes div.' + $(this).attr('class'), $window).show();
        $(this).addClass('active');
    });
    
    $('.routes .content .structure .sub', $window).each(function () {
        if ($(this).has('span.name:contains("Match data")').length) {
            $(this).prev().find('.set.name').addClass('matching');
        }
    });
    
    /* Hide data structures initially */
    $('.data .structure', $window).hide();
    
    $('.data .tab li', $window).click(function () {
        var structure = $(this).attr('class');
        
        $('.data .tab li', $window).removeClass('active');
        $('.data .structure', $window).hide();
        $('.data .structure.' + structure, $window).show();
        
        $('.data .util li.console', $window).unbind('click')
            .click(function () {
                if (console)
                    // FIXME: Blessed hash references aren't evaluated properly
                    console.log(dancer_plugin_debugtoolbar.YAML.eval(
                            info.data[structure].yaml));
            });
        
        $(this).addClass('active');
    });
    
    $('.structure li div.field', $window).each(function () {
        if ($(this).nextAll('div.sub').length > 0) {
            $('<span class="expand"></span>').prependTo($(this))
                .click(function () {
                    $(this).parent().nextAll('div.sub').toggle();
                    
                    var expanded = $(this).parent().nextAll('div.sub')
                        .is(':visible');
                    
                    $(this).parent().toggleClass('expanded', expanded);
                });
        }
        else {
            $('<span class="placeholder" />').prependTo($(this));
        }
    });
});
