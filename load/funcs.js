module.exports = {
    createPayloadVars: createPayloadVars
}

var counter = 0;
var sources = ["BACKEND", "CHANNEL_1", "CHANNEL_2", "CHANNEL_3"];
var eventTypes = ["WITHDRAWAL", "PAGEVIEW", "LOYALTY_OPTOUT", "LOYALTY_OPTIN"];

function getRandomInt(max) {
    return Math.floor(Math.random() * Math.floor(max));
}

function getRandomSourceEventIdx() {
    return getRandomInt(sources.length);
}

function getEventPayload(eventType) {
    switch (eventType) {
        case 'WITHDRAWAL':
            return {
                amount: 20
            };

        case 'PAGEVIEW':
            return {
                pageName: 'INDEX'
            };

        case 'PAGEVIEW':
            return {
                pageName: 'INDEX'
            };

        case 'LOYALTY_OPTOUT':
        case 'LOYALTY_OPTIN':
            return {};

        default:
            return {};
    }
}

function generateUUID() { // Public Domain/MIT
    var d = new Date().getTime();//Timestamp
    var d2 = ((typeof performance !== 'undefined') && performance.now && (performance.now()*1000)) || 0;//Time in microseconds since page-load or 0 if unsupported
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16;//random number between 0 and 16
        if(d > 0){//Use timestamp until depleted
            r = (d + r)%16 | 0;
            d = Math.floor(d/16);
        } else {//Use microseconds since page-load if supported
            r = (d2 + r)%16 | 0;
            d2 = Math.floor(d2/16);
        }
        return (c === 'x' ? r : (r & 0x3 | 0x8)).toString(16);
    });
}

function createPayloadVars(context, events, done) {
    counter += 1;
    var idx = getRandomSourceEventIdx();
    context.vars.address = context.vars.street + " " + getRandomInt(30) + ", " + context.vars.city;
    context.vars.source = sources[idx];
    context.vars.event = eventTypes[idx];
    context.vars.timestamp = new Date().toISOString();
    context.vars.eventId = generateUUID();
    context.vars.eventPayload = getEventPayload(eventTypes[idx]);
    return done();
}