jQuery(function($) {
    // TODO Due to copy/pasting we serve two classes here... better unify them
    $('span.autoincrementEditableLock,span.randomuniqueEditableLock').click(function() {
        var $this = $(this);
        if($this.hasClass('randomuniqueEditableLock') || confirm(jsi18n.get('Do you really want to edit this value?\nYou will have to make sure, that it is unique!'))) {
            $this.closest('span.autoincrementForm,span.randomuniqueForm').find('input.autoincrementEditable,input.randomuniqueEditable').removeAttr('readonly');
            $this.hide();
        }
    });
});
