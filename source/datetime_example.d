/++
時刻・日付の操作についてまとめます。
+/
module datetime_example;

/++
# 時間を表す7つの型

以下の説明では、「時刻」「時間」「期間」を明確に使い分けます。
+/
@safe unittest
{
    // それぞれの型は以下のモジュールでimportできます
    import core.time: Duration, MonoTime;
    import std.datetime: SysTime, Date, TimeOfDay, DateTime, Interval;
}

/++

## 1. 「時間」 $(D Duration)
Durationは「時間」を表す型です。
ここでの「時間」とは、10秒間とか、3時間、のような、時間的な長さを表す表現です。
各種単位の「時間」を得るには、hours関数や、seconds関数のようなものを core.time からimportして使います。
+/
@safe unittest
{
    import core.time: Duration, hours, minutes, seconds, msecs, usecs, nsecs;

    // 3600秒間なら以下のように得ます。
    auto dur = 3600.seconds;

    // 3600秒間は、1時間と同等です。
    assert(dur == 1.hours);

    // 得た「時間」の型は Duration です。
    static assert(is(typeof(60.minutes) == Duration));

}

/++
## 2. 「時刻」 $(D SysTime)

SysTimeは「時刻」を表す型です。
現在時刻を取得するには、 std.datetime でimportできるClockのメソッドを使用します。
+/
@safe unittest
{
    import std.datetime: Clock, SysTime;
    auto tim = Clock.currTime();

    // 時計から得た「時刻」の型は SysTime です
    static assert(is(typeof(tim) == SysTime));
}

/++
## 3. 「時刻」 $(D DateTime)

DateTimeは「時刻」を表す型です。
ただし、SysTimeとは内部表現が違います。
SysTimeは時差を考慮しますが、DateTimeは考慮せず、ただ
何年何月何日の何時何分何秒という情報だけを持っています。
ミリ秒以下の情報も持ちません。
+/
@safe unittest
{
    import std.datetime: DateTime, SysTime;

    auto xmasEve = DateTime(2019, 12, 24, 21, 0, 0);
    static assert(is(typeof(xmasEve) == DateTime));

    // DateTimeからSysTimeを作ることもできます
    auto xmasEve2 = SysTime(xmasEve);

    // 逆に、SysTimeからDateTimeは、castで変換できます
    auto xmasEve3 = cast(DateTime)xmasEve2;
}

/++
## 4. 「日付」 $(D Date)

Dateは、DateTimeのうち、何年何月何日(つまり日付)の部分です。
+/
@safe unittest
{
    import std.datetime: Date;
    auto newyear = Date(2020, 1, 1);
}

/++
## 5. $(D TimeOfDay)

TimeOfDayは、DateTimeのうち、「何時何分何秒」の部分です。
+/

@safe unittest
{
    import std.datetime: TimeOfDay, Date, DateTime;
    auto noon = TimeOfDay(12, 0, 0);
    // DateとTimeOfDayを組み合わせて、DateTimeが作れます
    auto newyearNoon = DateTime(Date(2020, 1, 1), noon);
}


/++
## 6. 「期間」 $(D Interval)

2つの「時刻」の間の時間を「期間」とすることができます。
+/
@safe unittest
{
    import std.datetime: Interval, DateTime;
    auto interval = Interval!DateTime(
        DateTime(2019, 12, 25,  0, 0, 0),
        DateTime(2020, 1,  1,  12, 0, 0));
}


/++
## 7. 「時間」 $(D MonoTime)

2つ目の「時間」 MonoTime は、ベンチマークやゲームのFPSの計算などで
使用される、高精度な時間単位を扱います。
「時間」を測定するストップウォッチで得られます。
+/
@safe unittest
{
    import core.time: Duration;
    import std.datetime.stopwatch: StopWatch, AutoStart;
    // ストップウォッチの定義と同時に計測開始
    StopWatch sw = AutoStart.yes;
    // peekで計測開始からの時間を得ます
    auto monotime = sw.peek();

    // totalメソッドで各単位の整数が得られます
    assert(monotime.total!"msecs" == 0);

    // Durationにキャストすることもできます
    auto peekDur = cast(Duration)monotime;
}


/++
# SysTimeと文字列の変換
+/
@safe unittest
{
    import std.datetime;
    import std.format;

    auto tim = SysTime(DateTime(2019, 5, 1, 10, 0, 0));

    // 日本でよく見る時刻の文字列表現 YYYY/MM/DD hh:mm:ss.SSS
    // にするには以下のようにします
    auto timstr = format!"%04d/%02d/%02d %02d:%02d:%02d.%03d"(
        tim.year, tim.month,  tim.day,
        tim.hour, tim.minute, tim.second,
        tim.fracSecs.total!"msecs");
    assert(timstr == "2019/05/01 10:00:00.000");

    // 特にフォーマットを気にしないで、わかればいい程度なら toString
    auto timstrDefault = tim.toString();

    // YYYY-Mon-DD HH:MM:SS.FFFFFFFTZ 形式
    auto timstrSimple = tim.toSimpleString();
    assert(timstrSimple == "2019-May-01 10:00:00");
    // 逆変換
    auto timSimple    = SysTime.fromSimpleString(timstrSimple);
    assert(timSimple == tim);

    // ISOで定められているやつ YYYYMMDDTHHMMSS.FFFFFFFTZ
    auto timstrISO = tim.toISOString();
    assert(timstrISO == "20190501T100000");
    // 逆変換
    auto timISO    = SysTime.fromISOString(timstrISO);
    assert(timISO == tim);

    // ISOで定められているやつ(別版) YYYY-MM-DDThh:MM:SS.FFFFFFFTZ
    auto timstrISOExt = tim.toISOExtString();
    assert(timstrISOExt == "2019-05-01T10:00:00");
    // 逆変換
    auto timISOExt    = SysTime.fromISOExtString(timstrISOExt);
    assert(timISOExt == tim);
}

/++
# Durationの使い方
+/
@safe unittest
{
    import core.time;
    import std.datetime;
    import std.format;

    // 平成元年 1/8 10時
    auto timA = SysTime(DateTime(1989, 1, 8, 10, 0, 0));
    // 令和元年 5/1 10時
    auto timB = SysTime(DateTime(2020, 5, 1, 10, 0, 0));
    // 2つの「時刻」から「時間」を得る
    auto dur = timB - timA;

    // 平成の秒数
    assert(dur.total!"seconds" == 988_070_400);

    // 平成の時間を日数とミリ秒に分解
    // 注) Durationは時刻情報ではないので、うるう年や1か月に何日あるかなどの
    //     計算ができないため、days, hours, minutes, seconds...といった
    //     長さが変化しない"日"以下の単位にしか分解できません。
    auto heiseiTimes = dur.split!("days", "msecs");
    assert(heiseiTimes.days == 365*31 + 121); // 約31年とちょっと
    assert(heiseiTimes.msecs == 0);
}

/++
# StopWatchの使い方
+/
@safe unittest
{
    import core.thread;
    import std.datetime.stopwatch;

    void wait() @trusted
    {
        Thread.sleep(1.msecs);
    }

    // ストップウォッチを作成
    StopWatch sw;

    // running プロパティで計測中かどうかが確認できる
    assert(!sw.running);

    // ストップウォッチで時間計測を開始
    sw.start();
    assert(sw.running);

    // 計測中のストップウォッチで計測結果を確認
    auto t1 = sw.peek();
    wait();

    // ストップウォッチを一時停止
    sw.stop();
    assert(!sw.running);

    // (停止中は計測値が進みません)
    auto t2 = sw.peek();
    assert(t2 > t1);
    wait();

    // 停止中のストップウォッチの計測結果を確認
    // 計測値が進んでいないので、1ナノ秒も変わらず完全に一致する。
    auto t3 = sw.peek();
    assert(t2 == t3);

    // ストップウォッチを再開
    sw.start();
    assert(sw.running);
    wait();

    // ストップウォッチを確認
    auto t4 = sw.peek();
    assert(t4 > t3);

    // 計測中にストップウォッチをリセット
    sw.reset();

    assert(sw.peek() <= t4);
}