(function($) {

    $.fn.defaultify = function(defaultValue) {

        return this.each(function(i) {

            var $this = $(this), value;

            value = defaultValue ? defaultValue : $this.val();
            $this.val(value);

            $this.focus(function(e) {
                if ($.trim($this.val()) == value) $this.val("");
            });

            $this.blur(function(e) {
                if ($.trim($this.val()) == "") $this.val(value);
            });
        });
    };

})(jQuery);