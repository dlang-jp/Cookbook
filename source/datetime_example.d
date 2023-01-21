/++
時刻・日付

時刻・日付の操作についてまとめます。

Source: $(LINK_TO_SRC source/_datetime_example.d)
+/
module datetime_example;

/++
# 時間を表す7つの型

Dには日時に関する型が複数定義されており、その性質によって役割が異なります。

以下の説明では、「システムタイム(日時)」「日時」「日付」「時刻」「時間」「モノトニックタイム(時間)」「期間」を明確に使い分けます。
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
## 2. 「システムタイム(日時)」 $(D SysTime)

SysTimeは「時差を考慮した日時」を表す型です。
現在日時を取得するには、 std.datetime でimportできるClockのメソッドを使用します。
+/
@safe unittest
{
    import std.datetime: Clock, SysTime;

    // Clock.currTimeでは、OSで設定されたタイムゾーンに基づく時差を持った「ローカル日時」が得られます。
    auto localTime = Clock.currTime();

    // 時計から得た「時刻」の型は SysTime です
    static assert(is(typeof(localTime) == SysTime));
}

/++
## 3. 「日時」 $(D DateTime)

DateTimeは「時差を考慮しない日時」を表す型です。
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

    // Dateは差分を求めることもできます。
    //
    {
        // 一ヶ月前の日付を求めます。
        auto date = Date(2019, 8, 31);
        assert(date.add!"months"(-1) == Date(2019, 7, 31));
    }

    {
        // 一ヶ月前を表す方法は、可能であれば前月の同日同時刻を表し、
        // 前日に同日が存在しない場合は差分を計算して付け足します。
        // なので3月31日は以下のようになります。
        auto date = Date(2019, 3, 31);
        assert(date.add!"months"(-1) == Date(2019, 3, 3));

        // うるう年のときの結果も異なります。
        //
        date = Date(2019, 3, 29);
        assert(date.add!"months"(-1) == Date(2019, 3, 1));
        date = Date(2016, 3, 29);
        assert(date.add!"months"(-1) == Date(2016, 2, 29));
    }
}

/++
## 5. 「時刻」$(D TimeOfDay)

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
## 7. 「モノトニックタイム(時間)」 $(D MonoTime)

2つ目の「時間」 MonoTime は、ベンチマークやゲームのFPSの計算などで使用される、
高精度な時間単位を扱います。
また、NTPによる巻き戻しがおこらず、単調増加(monotonic)であることが特徴です。
「時間」を測定するストップウォッチで得られます。
+/
@safe unittest
{
    import core.time: Duration;
    import std.datetime.stopwatch: StopWatch, AutoStart;
    // ストップウォッチの定義と同時に計測開始
    auto sw = StopWatch(AutoStart.yes);
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
    // 2つの「日時」から「時間」を得る
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

/++
# タイムゾーンの扱い
+/
@safe unittest
{
    import core.time : hours;
    import std.datetime.date : DateTime;
    import std.datetime.systime: Clock, SysTime;
    import std.datetime.timezone : LocalTime, SimpleTimeZone, UTC;

    // LocalTimeクラスはプログラムが実行されているのシステムのローカルタイムゾーンを表す。
    // Clockで取得できる現在時刻にはこのタイムゾーン情報が含まれる。
    auto tim1 = Clock.currTime();
    assert(tim1.timezone is LocalTime());

    // UTCクラスはUTCのタイムゾーンを表す。
    // タイムゾーンを指定して作成されたSysTimeは時差情報を含む。
    auto tim2 = SysTime(DateTime(2019, 5, 1, 10, 0, 0), UTC());
    assert(tim2.toSimpleString() == "2019-May-01 10:00:00Z");

    // ローカル日時は toUTC でUTC基準に変更できる
    auto utc = tim1.toUTC();
    assert(utc.timezone is UTC());
    assert(utc.toUTC() == utc); // 複数回実行しても変化しない

    // UTC日時は toLocalTime でローカル日時に変換できる
    auto local = tim2.toLocalTime();
    assert(local.timezone is LocalTime());
    assert(local.toLocalTime() == local); // 複数回実行しても変化しない

    // UTCから任意のタイムゾーンに変換する。
    auto JST = new immutable SimpleTimeZone(9.hours);
    auto tim3 = tim2.toOtherTZ(JST);
    assert(tim3.toSimpleString() == "2019-May-01 19:00:00+09:00");
}

/++
# 「今日」の日付を得る
+/
@safe unittest
{
    import std.datetime : Clock, Date;

    // 現在のシステム日時（ローカル）を得て、日付部分を取り出すことで今日の日付を得ます。
    Date today = cast(Date) Clock.currTime();
}

/++
# 値の構築方法に関するパターン

std.datetimeの各型は、値の直接指定か、ベースとなる型＋付加情報、というパターンでコンストラクタを使って構築します。
+/
@safe unittest
{
    import std.datetime;

    // 直接値を指定できるタイプの型
    //     Date, TimeOfDay, DateTime
    auto date = Date(2020, 10, 20);
    auto time = TimeOfDay(12, 34, 56);
    auto dt1 = DateTime(2021, 12, 31, 10, 20, 30);

    // 他の値から合成するタイプの型
    //     DateTime, SysTime, Interval

    // 日時（DateTime） = 日付（Date） + 時刻（TimeOfDay、未指定の場合は 0時0分0秒）
    auto dt2 = DateTime(date); // 0時0分0秒の日時を得るにはこれが簡単です
    auto dt3 = DateTime(date, time);

    // 日時（SysTime）  = 日時（DateTime） + タイムゾーン（TimeZone、未指定の場合は OSのタイムゾーンに基づく時差）
    auto st1 = SysTime(dt1); // ローカル日時として、OSのタイムゾーンから時差が設定されます
    auto st2 = SysTime(dt2, UTC());

    // 期間 = 開始時点 + 終了時点
    auto interval = Interval!DateTime(dt2, dt1);
}

/++
# DateTimeからDateを得るなど、上位の複合型から一部を取り出す方法

多くの場合、目的の部分型を得るためのプロパティがあります。
DateTime型の場合は `date` と `timeOfDay` プロパティで取り出します。
Interval型の場合は `begin` と `end` プロパティで取り出します。

SysTime型の場合は、DateTime型やDate型へ直接キャストすることで部分型を得ることができます。
+/
@safe unittest
{
    import std.datetime;

    // 直接構築したあと、日付や時刻部分を取り出す
    auto dt = DateTime(2021, 12, 31, 10, 20, 30);
    auto date = dt.date;
    auto time = dt.timeOfDay;
    assert(date.year == 2021 && date.month == 12 && date.day == 31);
    assert(time.hour == 10 && time.minute == 20 && time.second == 30);

    auto interval = Interval!Date(Date(2020, 1, 1), Date(2021, 12, 31));
    assert(interval.begin == Date(2020, 1, 1));
    assert(interval.end == Date(2021, 12, 31));

    auto st = Clock.currTime();
    Date date2 = cast(Date) st;
    TimeOfDay time2 = cast(TimeOfDay) st;
    DateTime dt2 = cast(DateTime) st;

    assert(date2.year == st.year && date2.month == st.month && date2.day == st.day);
    assert(time2.hour == st.hour && time2.minute == st.minute && time2.second == st.second);
    assert(dt2.year == st.year && dt2.month == st.month && dt2.day == st.day);
    assert(dt2.hour == st.hour && dt2.minute == st.minute && dt2.second == st.second);
}

/++
# Unix timeとSysTimeの相互変換方法、Unix timeの作成方法

Unix timeは UTC時間の1970年1月1日 0時0分0秒からの秒数となります。
これはタイムゾーンがUTC基準と定められていることから、
タイムゾーン情報を持つ SysTimeのみ が相互変換の方法を提供しています。
+/
@safe unittest
{
    import std.datetime;

    // ローカル時刻を想定したUnix時間をSysTimeへ変換
    long unixtime = 1640913630; // 2021-12-31 01:20:30 + 00:00

    // テスト環境が不定のためタイムゾーンを固定します
    immutable localTZ = new SimpleTimeZone(9.hours, "JST");

    // fromUnixTimeにタイムゾーンを指定するとSysTimeに反映されます。
    // Localのタイムゾーンは省略するとローカルタイムゾーン（日本ならJSTで同じく+09:00）です。
    auto stLocal = SysTime.fromUnixTime(unixtime, localTZ); // 2021-12-31 10:20:30 + 09:00
    auto stUTC = SysTime.fromUnixTime(unixtime, UTC());     // 2021-12-31 01:20:30 + 00:00

    assert(cast(Date) stLocal == Date(2021, 12, 31));
    assert(cast(TimeOfDay) stLocal == TimeOfDay(10, 20, 30));
    assert(stLocal.timezone !is LocalTime()); // 構築時にタイムゾーンを省略した場合はLocalTimeになります
    assert(cast(Date) stUTC == Date(2021, 12, 31));
    assert(cast(TimeOfDay) stUTC == TimeOfDay(1, 20, 30));
    assert(stUTC.timezone is UTC());

    // Unix時間にする場合
    auto utFromLocal = stLocal.toUnixTime();
    auto utFromUTC = stUTC.toUnixTime();

    assert(utFromLocal == unixtime);
    assert(utFromUTC == unixtime);

    // 日時を指定して Unix time を作成する
    auto ut1 = SysTime(DateTime(1970, 1, 1, 0, 0, 0), UTC()).toUnixTime();
    assert(ut1 == 0);
    // 元のSysTimeがローカル時刻でもUnix timeはUTC基準です
    auto ut2 = SysTime(DateTime(2021, 12, 31, 23, 59, 59), localTZ).toUnixTime();
    assert(ut2 == 1640962799);
}

/++
# 日時文字列を組み込みの日時型（SysTime）に変換する簡便な方法

外部ライブラリを利用できる場合、`dateparser` パッケージの `parse` 関数を利用する方法が簡単です。

See_Also: https://code.dlang.org/packages/dateparser
+/
unittest
{
    import dateparser;
    import std.datetime;

    // SysTime型が得られます
    SysTime date1 = parse("2023-01-01");
    SysTime date2 = parse("2023/01/01");
    SysTime date3 = parse("2023/01/01 12:34:56"); // スペース区切りの時刻もOKです

    assert(date1 == SysTime(DateTime(2023, 1, 1)));
    assert(date2 == SysTime(DateTime(2023, 1, 1)));
    assert(date3 == SysTime(DateTime(2023, 1, 1, 12, 34, 56)));
}
