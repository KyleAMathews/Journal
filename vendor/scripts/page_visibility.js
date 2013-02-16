(function() {
    var hidden = "hidden";

    // Standards:
    if (hidden in document)
        document.addEventListener("visibilitychange", onchange);
    else if ((hidden = "mozHidden") in document)
        document.addEventListener("mozvisibilitychange", onchange);
    else if ((hidden = "webkitHidden") in document)
        document.addEventListener("webkitvisibilitychange", onchange);
    else if ((hidden = "msHidden") in document)
        document.addEventListener("msvisibilitychange", onchange);

    // IE 9 and lower:
    else if ('onfocusin' in document)
        document.onfocusin = document.onfocusout = onchange;

    // All others:
    else
        window.onfocus = window.onblur = onchange;

    function onchange (evt) {
        evt = evt || window.event;

        if (evt.type == "focus" || evt.type == "focusin") {
            app.eventBus.trigger("visibilitychange", "visible");
        }
        else if (evt.type == "blur" || evt.type == "focusout") {
            app.eventBus.trigger("visibilitychange", "hidden");
        }
        else {
            state = this[hidden] ? "hidden" : "visible";
            app.eventBus.trigger("visibilitychange", state);
        }
    }
})();
