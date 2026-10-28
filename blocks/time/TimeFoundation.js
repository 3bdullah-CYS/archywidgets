.pragma library

// OmaDesk — TimeFoundation
// Reusable domain logic and mathematical calculations for all TimeBlock variants.
// Pure functions only — no side effects, no timers, no processes.

function isValidDate(date) {
  return Boolean(date && date instanceof Date && !isNaN(date.getTime()));
}

function pad2(n) {
  return (n < 10 ? "0" : "") + n;
}

function getHours(date) {
  if (!isValidDate(date)) return "--";
  return pad2(date.getHours());
}

function getMinutes(date) {
  if (!isValidDate(date)) return "--";
  return pad2(date.getMinutes());
}

function getSeconds(date) {
  if (!isValidDate(date)) return "--";
  return pad2(date.getSeconds());
}

function getHmString(date) {
  return getHours(date) + ":" + getMinutes(date);
}

function getTimeString(date, showSeconds) {
  var hm = getHmString(date);
  if (showSeconds) {
    return hm + ":" + getSeconds(date);
  }
  return hm;
}

function getAnalogAngles(date) {
  if (!isValidDate(date)) {
    return { hoursAngle: 0, minutesAngle: 0, secondsAngle: 0 };
  }
  var h = date.getHours();
  var m = date.getMinutes();
  var s = date.getSeconds();
  var hoursAngle = ((h % 12) + m / 60.0) * 30.0;
  var minutesAngle = (m + s / 60.0) * 6.0;
  var secondsAngle = s * 6.0;
  return {
    hoursAngle: hoursAngle,
    minutesAngle: minutesAngle,
    secondsAngle: secondsAngle
  };
}

var TimeFoundation = {
  isValidDate: isValidDate,
  pad2: pad2,
  getHours: getHours,
  getMinutes: getMinutes,
  getSeconds: getSeconds,
  getHmString: getHmString,
  getTimeString: getTimeString,
  getAnalogAngles: getAnalogAngles
};

if (typeof globalThis !== "undefined") {
  globalThis.TimeFoundation = TimeFoundation;
}
