#include "analytics.h"

#include <linux/input-event-codes.h>

#include <algorithm>
#include <chrono>
#include <cerrno>
#include <cctype>
#include <cstdio>
#include <cstdlib>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <iomanip>
#include <map>
#include <sstream>
#include <string>
#include <utility>

namespace {
using Clock = std::chrono::system_clock;

struct ParsedData {
  std::map<std::string, std::uint64_t> dailyWords;
  std::map<std::string, std::uint64_t> dailyTypingSeconds;
  std::map<std::string, std::uint64_t> dailyTrackedSeconds;
  std::string trackingMode = "onlyWhenSound";
};

std::string jsonEscape(const std::string &value) {
  std::string out;
  out.reserve(value.size() + 2);

  for (char c : value) {
    switch (c) {
      case '\\': out += "\\\\"; break;
      case '"': out += "\\\""; break;
      case '\b': out += "\\b"; break;
      case '\f': out += "\\f"; break;
      case '\n': out += "\\n"; break;
      case '\r': out += "\\r"; break;
      case '\t': out += "\\t"; break;
      default:
        out += c;
        break;
    }
  }

  return out;
}

std::string readFile(const std::string &path) {
  std::ifstream file(path);
  if (!file.is_open()) {
    return {};
  }

  std::ostringstream buffer;
  buffer << file.rdbuf();
  return buffer.str();
}

bool writeFileAtomically(const std::string &path, const std::string &data) {
  namespace fs = std::filesystem;

  try {
    const fs::path target(path);
    const fs::path parent = target.parent_path();

    if (!parent.empty()) {
      fs::create_directories(parent);
    }

    const fs::path temp = target.string() + ".tmp";

    {
      std::ofstream file(temp, std::ios::out | std::ios::trunc);
      if (!file.is_open()) {
        return false;
      }

      file << data;
      file.flush();

      if (!file.good()) {
        file.close();
        std::error_code ignored;
        fs::remove(temp, ignored);
        return false;
      }
    }

    std::error_code error;
    fs::rename(temp, target, error);

    if (error) {
      // Some filesystems don't replace an existing file with rename().
      fs::remove(target, error);
      fs::rename(temp, target, error);
    }

    if (error) {
      fs::remove(temp, error);
      return false;
    }

    return true;
  } catch (...) {
    return false;
  }
}

std::string extractObject(const std::string &json,
                          const std::string &key) {
  const std::string needle = "\"" + key + "\"";
  const std::size_t keyPos = json.find(needle);

  if (keyPos == std::string::npos) {
    return {};
  }

  const std::size_t colon = json.find(':', keyPos + needle.size());
  if (colon == std::string::npos) {
    return {};
  }

  const std::size_t objectStart = json.find('{', colon + 1);
  if (objectStart == std::string::npos) {
    return {};
  }

  int depth = 0;
  bool inString = false;
  bool escaped = false;

  for (std::size_t i = objectStart; i < json.size(); ++i) {
    const char c = json[i];

    if (inString) {
      if (escaped) {
        escaped = false;
      } else if (c == '\\') {
        escaped = true;
      } else if (c == '"') {
        inString = false;
      }
      continue;
    }

    if (c == '"') {
      inString = true;
      continue;
    }

    if (c == '{') {
      ++depth;
    } else if (c == '}') {
      --depth;
      if (depth == 0) {
        return json.substr(objectStart, i - objectStart + 1);
      }
    }
  }

  return {};
}

std::map<std::string, std::uint64_t> parseNumberObject(
    const std::string &object) {
  std::map<std::string, std::uint64_t> result;

  std::size_t pos = 0;

  while (pos < object.size()) {
    const std::size_t keyStart = object.find('"', pos);
    if (keyStart == std::string::npos) {
      break;
    }

    const std::size_t keyEnd = object.find('"', keyStart + 1);
    if (keyEnd == std::string::npos) {
      break;
    }

    const std::string key = object.substr(
        keyStart + 1, keyEnd - keyStart - 1);

    const std::size_t colon = object.find(':', keyEnd + 1);
    if (colon == std::string::npos) {
      break;
    }

    std::size_t numberStart = colon + 1;
    while (numberStart < object.size() &&
           std::isspace(static_cast<unsigned char>(object[numberStart]))) {
      ++numberStart;
    }

    std::size_t numberEnd = numberStart;
    while (numberEnd < object.size() &&
           std::isdigit(static_cast<unsigned char>(object[numberEnd]))) {
      ++numberEnd;
    }

    if (numberEnd > numberStart) {
      try {
        const auto value = std::stoull(
            object.substr(numberStart, numberEnd - numberStart));
        result[key] = value;
      } catch (...) {
        // Ignore malformed individual entries.
      }
    }

    pos = numberEnd;
    if (pos == numberStart) {
      ++pos;
    }
  }

  return result;
}

std::string parseStringValue(const std::string &json,
                             const std::string &key,
                             const std::string &fallback) {
  const std::string needle = "\"" + key + "\"";
  const std::size_t keyPos = json.find(needle);

  if (keyPos == std::string::npos) {
    return fallback;
  }

  const std::size_t colon = json.find(':', keyPos + needle.size());
  if (colon == std::string::npos) {
    return fallback;
  }

  const std::size_t quoteStart = json.find('"', colon + 1);
  if (quoteStart == std::string::npos) {
    return fallback;
  }

  const std::size_t quoteEnd = json.find('"', quoteStart + 1);
  if (quoteEnd == std::string::npos) {
    return fallback;
  }

  return json.substr(quoteStart + 1, quoteEnd - quoteStart - 1);
}

ParsedData loadData(const std::string &path) {
  ParsedData data;
  const std::string json = readFile(path);

  if (json.empty()) {
    return data;
  }

  data.dailyWords = parseNumberObject(
      extractObject(json, "dailyWords"));

  data.dailyTypingSeconds = parseNumberObject(
      extractObject(json, "dailyTypingSeconds"));

  data.dailyTrackedSeconds = parseNumberObject(
      extractObject(json, "dailyTrackedSeconds"));

  const std::string mode =
      parseStringValue(json, "trackingMode", data.trackingMode);

  if (mode == "onlyWhenSound" || mode == "always") {
    data.trackingMode = mode;
  }

  return data;
}

std::string serializeNumberObject(
    const std::map<std::string, std::uint64_t> &data) {
  std::ostringstream out;
  out << "{";

  bool first = true;
  for (const auto &[key, value] : data) {
    if (!first) {
      out << ",";
    }

    first = false;
    out << "\"" << jsonEscape(key) << "\":" << value;
  }

  out << "}";
  return out.str();
}

std::string serializeData(const ParsedData &data) {
  std::ostringstream out;

  out << "{";
  out << "\"dailyWords\":"
      << serializeNumberObject(data.dailyWords) << ",";
  out << "\"dailyTypingSeconds\":"
      << serializeNumberObject(data.dailyTypingSeconds) << ",";
  out << "\"dailyTrackedSeconds\":"
      << serializeNumberObject(data.dailyTrackedSeconds) << ",";
  out << "\"trackingMode\":\""
      << jsonEscape(data.trackingMode) << "\"";
  out << "}";

  return out.str();
}

std::int64_t nowEpochSeconds() {
  return std::chrono::duration_cast<std::chrono::seconds>(
             Clock::now().time_since_epoch())
      .count();
}

std::tm localTime(std::time_t value) {
  std::tm result{};

#if defined(_POSIX_VERSION)
  localtime_r(&value, &result);
#else
  const std::tm *ptr = std::localtime(&value);
  if (ptr) {
    result = *ptr;
  }
#endif

  return result;
}

std::string dateKeyFromEpoch(std::int64_t epochSeconds) {
  const std::time_t time = static_cast<std::time_t>(epochSeconds);
  const std::tm tm = localTime(time);

  char buffer[11]{};
  std::strftime(buffer, sizeof(buffer), "%Y-%m-%d", &tm);
  return buffer;
}

std::int64_t nextLocalMidnight(std::int64_t epochSeconds) {
  const std::time_t currentTime =
      static_cast<std::time_t>(epochSeconds);
  std::tm tm = localTime(currentTime);

  tm.tm_hour = 0;
  tm.tm_min = 0;
  tm.tm_sec = 0;
  tm.tm_mday += 1;
  tm.tm_isdst = -1;

  const std::time_t result = std::mktime(&tm);
  return static_cast<std::int64_t>(result);
}

bool isWordKey(unsigned int code) {
  // Alphabetic keys.
  if (code >= KEY_A && code <= KEY_Z) {
    return true;
  }

  // Number row.
  if (code >= KEY_1 && code <= KEY_0) {
    return true;
  }

  // Numpad digits and decimal point.
  if (code >= KEY_KP1 && code <= KEY_KP0) {
    return true;
  }

  if (code == KEY_KPDOT) {
    return true;
  }

  // Punctuation that can occur inside a word.
  switch (code) {
    case KEY_MINUS:
    case KEY_EQUAL:
    case KEY_LEFTBRACE:
    case KEY_RIGHTBRACE:
    case KEY_BACKSLASH:
    case KEY_SEMICOLON:
    case KEY_APOSTROPHE:
    case KEY_GRAVE:
    case KEY_COMMA:
    case KEY_DOT:
    case KEY_SLASH:
      return true;

    default:
      return false;
  }
}

bool isWordBoundary(unsigned int code) {
  return code == KEY_SPACE ||
         code == KEY_ENTER ||
         code == KEY_KPENTER ||
         code == KEY_TAB;
}

bool isWordBackspace(unsigned int code) {
  return code == KEY_BACKSPACE;
}

} // namespace

struct AnalyticsTracker::Impl {
  explicit Impl(const std::string &path)
      : statePath(path.empty()
                      ? AnalyticsTracker::defaultStatePath()
                      : path),
        data(loadData(statePath)) {}

  std::string statePath;
  ParsedData data;

  bool enabled = false;
  bool dirty = false;

  std::uint64_t currentWordLength = 0;

  bool hasPreviousKey = false;
  std::int64_t previousKeyEpoch = 0;

  bool hasPendingFlush = false;
};

AnalyticsTracker::AnalyticsTracker(const std::string &statePath)
    : impl_(new Impl(statePath)) {}

AnalyticsTracker::~AnalyticsTracker() {
  shutdown();
  delete impl_;
  impl_ = nullptr;
}

std::string AnalyticsTracker::defaultStatePath() {
  const char *xdgStateHome = std::getenv("XDG_STATE_HOME");

  if (xdgStateHome && *xdgStateHome) {
    return std::string(xdgStateHome) +
           "/omarchy/omavibes-analytics.json";
  }

  const char *home = std::getenv("HOME");

  if (home && *home) {
    return std::string(home) +
           "/.local/state/omarchy/omavibes-analytics.json";
  }

  return ".local/state/omarchy/omavibes-analytics.json";
}

void AnalyticsTracker::setEnabled(bool enabled) {
  if (impl_->enabled == enabled) {
    return;
  }

  impl_->enabled = enabled;

  if (!enabled) {
    // Do not carry a word across disabled periods.
    impl_->currentWordLength = 0;
    impl_->hasPreviousKey = false;
    impl_->previousKeyEpoch = 0;
    flush();
  }
}

bool AnalyticsTracker::isEnabled() const {
  return impl_->enabled;
}

void AnalyticsTracker::recordKeyPress(unsigned int keyCode) {
  if (!impl_->enabled) {
    return;
  }

  const std::int64_t now = nowEpochSeconds();

  if (impl_->hasPreviousKey) {
    const std::int64_t gap =
        now - impl_->previousKeyEpoch;

    if (gap > 0 &&
        gap <= AnalyticsTracker::IDLE_THRESHOLD_SECONDS) {
      std::int64_t activeSeconds = 0;
      std::int64_t idleSeconds = 0;

      if (gap <= AnalyticsTracker::ACTIVE_THRESHOLD_SECONDS) {
        activeSeconds = gap;
      } else {
        idleSeconds = gap - AnalyticsTracker::ACTIVE_THRESHOLD_SECONDS;
        activeSeconds = AnalyticsTracker::ACTIVE_THRESHOLD_SECONDS;
      }

      // Allocate the interval across real local calendar dates.
      // This matters when typing crosses midnight.
      auto allocateInterval =
          [this, activeSeconds, idleSeconds, now, gap](
              std::int64_t startEpoch,
              std::int64_t endEpoch) {
            if (endEpoch <= startEpoch) {
              return;
            }

            std::int64_t cursor = startEpoch;
            const std::int64_t totalDuration = endEpoch - startEpoch;

            std::int64_t activeRemaining = activeSeconds;
            std::int64_t idleRemaining = idleSeconds;

            while (cursor < endEpoch) {
              const std::int64_t boundary =
                  nextLocalMidnight(cursor);

              const std::int64_t chunkEnd =
                  std::min(endEpoch, boundary);

              const std::int64_t chunk =
                  chunkEnd - cursor;

              const std::int64_t activeChunk =
                  (totalDuration > 0)
                      ? std::min(
                            activeRemaining,
                            chunk)
                      : 0;

              activeRemaining -= activeChunk;

              const std::int64_t idleChunk =
                  (totalDuration > 0)
                      ? std::min(
                            idleRemaining,
                            chunk - activeChunk)
                      : 0;

              idleRemaining -= idleChunk;

              const std::string key =
                  dateKeyFromEpoch(cursor);

              impl_->data.dailyTypingSeconds[key] +=
                  static_cast<std::uint64_t>(
                      std::max<std::int64_t>(0, activeChunk));

              impl_->data.dailyTrackedSeconds[key] +=
                  static_cast<std::uint64_t>(
                      std::max<std::int64_t>(0,
                                             activeChunk +
                                             idleChunk));

              cursor = chunkEnd;
            }

            (void)now;
            (void)gap;
          };

      allocateInterval(
          impl_->previousKeyEpoch,
          now);

      impl_->dirty = true;
    }
  }

  if (isWordBoundary(keyCode)) {
    if (impl_->currentWordLength > 0) {
      const std::string day = dateKeyFromEpoch(now);
      impl_->data.dailyWords[day] += 1;
      impl_->dirty = true;
    }

    impl_->currentWordLength = 0;
  } else if (isWordBackspace(keyCode)) {
    if (impl_->currentWordLength > 0) {
      --impl_->currentWordLength;
    }
  } else if (isWordKey(keyCode)) {
    ++impl_->currentWordLength;
  }

  impl_->hasPreviousKey = true;
  impl_->previousKeyEpoch = now;

  // Persist periodically from the caller rather than forcing a disk write
  // on every single key press.
  impl_->hasPendingFlush = true;
}

void AnalyticsTracker::flush() {
  if (!impl_->dirty && !impl_->hasPendingFlush) {
    return;
  }

  // Reload the current tracking-mode field so this component never
  // overwrites the user's QML-selected mode.
  const ParsedData diskData = loadData(impl_->statePath);
  impl_->data.trackingMode = diskData.trackingMode;

  const std::string json = serializeData(impl_->data);

  if (writeFileAtomically(impl_->statePath, json)) {
    impl_->dirty = false;
    impl_->hasPendingFlush = false;
  }
}

void AnalyticsTracker::shutdown() {
  if (!impl_) {
    return;
  }

  flush();

  impl_->currentWordLength = 0;
  impl_->hasPreviousKey = false;
  impl_->previousKeyEpoch = 0;
}

std::uint64_t AnalyticsTracker::wordsToday() const {
  const std::string today =
      dateKeyFromEpoch(nowEpochSeconds());

  const auto it = impl_->data.dailyWords.find(today);
  return it == impl_->data.dailyWords.end() ? 0 : it->second;
}

std::uint64_t AnalyticsTracker::typingSecondsToday() const {
  const std::string today =
      dateKeyFromEpoch(nowEpochSeconds());

  const auto it =
      impl_->data.dailyTypingSeconds.find(today);

  return it == impl_->data.dailyTypingSeconds.end()
             ? 0
             : it->second;
}

std::uint64_t AnalyticsTracker::idleSecondsToday() const {
  const std::string today =
      dateKeyFromEpoch(nowEpochSeconds());

  const auto tracked =
      impl_->data.dailyTrackedSeconds.find(today);

  const auto typing =
      impl_->data.dailyTypingSeconds.find(today);

  const std::uint64_t trackedValue =
      tracked == impl_->data.dailyTrackedSeconds.end()
          ? 0
          : tracked->second;

  const std::uint64_t typingValue =
      typing == impl_->data.dailyTypingSeconds.end()
          ? 0
          : typing->second;

  return trackedValue > typingValue
             ? trackedValue - typingValue
             : 0;
}

std::uint64_t AnalyticsTracker::trackedSecondsToday() const {
  const std::string today =
      dateKeyFromEpoch(nowEpochSeconds());

  const auto it =
      impl_->data.dailyTrackedSeconds.find(today);

  return it == impl_->data.dailyTrackedSeconds.end()
             ? 0
             : it->second;
}
