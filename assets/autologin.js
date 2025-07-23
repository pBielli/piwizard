// ==UserScript==
// @name         Bacheca CEM Autologin
// @namespace    http://tampermonkey.net/
// @version      1.1
// @description  Login automatico su Bacheca CEM
// @author       AutoScript
// @match        *://*/login*
// @grant        none
// ==/UserScript==

(function () {
    'use strict';

    function login() {
        // Funzione per simulare l'inserimento utente
        function setNativeValue(element, value) {
            const lastValue = element.value;
            element.value = value;

            // Trigger degli eventi necessari
            const event = new Event('input', { bubbles: true });
            const tracker = element._valueTracker;
            if (tracker) {
                tracker.setValue(lastValue);
            }
            element.dispatchEvent(event);
        }

        // Aspetta che il DOM React abbia montato gli elementi
        const interval = setInterval(() => {
            const usernameField = document.querySelector('input[name="username"]');
            const passwordField = document.querySelector('input[name="password"]');
            const loginButton = Array.from(document.querySelectorAll('button')).find(btn => btn.textContent.trim().toUpperCase() === 'LOGIN');

            if (usernameField && passwordField && loginButton) {
                clearInterval(interval);

                setNativeValue(usernameField, '%WEB_USERNAME%');
                setNativeValue(passwordField, '%WEB_PASSWORD%');

                // Delay per sicurezza
                setTimeout(() => {
                    loginButton.click();
                }, 300);
            }
        }, 200);
    }
    window.addEventListener('load', login, false);
})();