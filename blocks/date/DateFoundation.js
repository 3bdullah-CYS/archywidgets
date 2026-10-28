.pragma library

// OmaDesk — DateFoundation
// Pure algorithmic date & calendar calculations.
// Zero QML elements, zero timers, zero background processes.

function isValidDate(d) {
  return Boolean(d && typeof d.getTime === "function" && !isNaN(d.getTime()));
}

function getWeekBadgeText(d) {
  if (!isValidDate(d)) return "";
  var m = d.getMonth();
  var dom = d.getDate();
  var curYear = d.getFullYear();
  var isLeap = (curYear % 4 === 0 && curYear % 100 !== 0) || (curYear % 400 === 0);
  var mdays = [0, 31, isLeap ? 60 : 59, isLeap ? 91 : 90, isLeap ? 121 : 120, isLeap ? 152 : 151, isLeap ? 182 : 181, isLeap ? 213 : 212, isLeap ? 244 : 243, isLeap ? 274 : 273, isLeap ? 305 : 304, isLeap ? 335 : 334];
  var doy = mdays[m] + dom;
  var wk = Math.max(1, Math.min(53, Math.ceil(doy / 7)));
  return "W" + wk;
}

function buildCurrentWeekStrip(cur) {
  if (!isValidDate(cur)) return [];
  var dow = cur.getDay(); // 0 = Sun .. 6 = Sat
  var curDay = cur.getDate();
  var curMonth = cur.getMonth();
  var curYear = cur.getFullYear();
  var isLeap = (curYear % 4 === 0 && curYear % 100 !== 0) || (curYear % 400 === 0);
  var monthDays = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var prevMonthDays = monthDays[(curMonth + 11) % 12];
  var thisMonthDays = monthDays[curMonth];
  var labels = ["S", "M", "T", "W", "T", "F", "S"];
  var items = [];
  for (var i = 0; i < 7; i++) {
    var offset = i - dow;
    var dNum = curDay + offset;
    if (dNum < 1) {
      dNum = prevMonthDays + dNum;
    } else if (dNum > thisMonthDays) {
      dNum = dNum - thisMonthDays;
    }
    items.push({
      label: labels[i],
      dayNum: String(dNum),
      isToday: i === dow
    });
  }
  return items;
}

function buildMonthGrid(cur) {
  if (!isValidDate(cur)) return [];
  var curDay = cur.getDate();
  var curDow = cur.getDay(); // 0 = Sun .. 6 = Sat
  var curMonth = cur.getMonth();
  var curYear = cur.getFullYear();
  var isLeap = (curYear % 4 === 0 && curYear % 100 !== 0) || (curYear % 400 === 0);
  var monthDays = [31, isLeap ? 29 : 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  var prevMonthDays = monthDays[(curMonth + 11) % 12];
  var thisMonthDays = monthDays[curMonth];

  // Day of week of the 1st of the current month (0..6)
  var firstDow = (curDow - ((curDay - 1) % 7) + 7) % 7;
  var cells = [];
  for (var idx = 0; idx < 42; idx++) {
    var dayOffset = idx - firstDow + 1;
    var dNum = dayOffset;
    var inMonth = true;
    if (dayOffset < 1) {
      dNum = prevMonthDays + dayOffset;
      inMonth = false;
    } else if (dayOffset > thisMonthDays) {
      dNum = dayOffset - thisMonthDays;
      inMonth = false;
    }
    cells.push({
      dayNum: String(dNum),
      inMonth: inMonth,
      isToday: inMonth && (dayOffset === curDay),
      isWeekend: (idx % 7 === 0) || (idx % 7 === 6)
    });
  }
  return cells;
}

var DateFoundation = {
  isValidDate: isValidDate,
  getWeekBadgeText: getWeekBadgeText,
  buildCurrentWeekStrip: buildCurrentWeekStrip,
  buildMonthGrid: buildMonthGrid
};

if (typeof globalThis !== "undefined") {
  globalThis.DateFoundation = DateFoundation;
}
