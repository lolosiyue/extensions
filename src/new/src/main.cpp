#include <cstring>
#include <ctime>
#include <memory> // For std::unique_ptr

#include "mainwindow.h"
#include "settings.h"
#include "banpair.h"
#include "server.h"
#include "engine.h"
#include "room.h"         // AI模式需要
#include "serverplayer.h" // AI模式需要

#ifdef ANDROID
#include "android_assets.h"
#endif

#include <QDir>
#include <QTime>
#include <QFile>
#include <QTextStream>

// ============================================================================
//  SECTION 1: Windows 崩潰攔截 (最後一道防線)
// ============================================================================
#ifdef Q_OS_WIN
#include <windows.h>
#include <dbghelp.h>
#include <stdio.h>

// 這是最底層的 Windows 異常處理，當程式即將「消失」時會被呼叫
LONG WINAPI MyUnhandledExceptionFilter(EXCEPTION_POINTERS *pExceptionInfo)
{
    qWarning() << "CRASH DETECTED! Writing Emergency Dump...";

    QDateTime now = QDateTime::currentDateTime();
    // 確保 dmp 目錄存在
    QDir dir;
    if (!dir.exists("dmp"))
        dir.mkdir("dmp");

    QString dumpName = QString("dmp/EmergencyCrash_%1.dmp").arg(now.toString("yyyyMMdd_HHmmss"));
    HANDLE hFile = CreateFile((LPCWSTR)dumpName.utf16(), GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

    if (hFile != INVALID_HANDLE_VALUE)
    {
        MINIDUMP_EXCEPTION_INFORMATION mdei;
        mdei.ThreadId = GetCurrentThreadId();
        mdei.ExceptionPointers = pExceptionInfo;
        mdei.ClientPointers = FALSE;

        // 寫入完整記憶體 (MiniDumpWithFullMemory) 檔案會很大，但對於除錯 AI 邏輯很有用
        // 如果只要堆疊，改用 MiniDumpNormal
        MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), hFile, MiniDumpNormal, &mdei, NULL, NULL);
        CloseHandle(hFile);
        qWarning() << "Dump saved to" << dumpName;
    }

    // 可以在這裡把 Log flush 到硬碟
    return EXCEPTION_EXECUTE_HANDLER;
}
#endif

// ============================================================================
//  SECTION 2: Google Breakpad (應用層崩潰回報)
// ============================================================================
// 放寬條件：只要是 Windows + MSVC 編譯器就啟用
#if defined(WIN32) && defined(_MSC_VER)
#include "breakpad/client/windows/handler/exception_handler.h"

using namespace google_breakpad;

static bool callback(const wchar_t *dump_path, const wchar_t *id, void *, EXCEPTION_POINTERS *, MDRawAssertionInfo *, bool succeeded)
{
    if (succeeded)
        qWarning("Breakpad: Dump file created in %ls, dump guid is %ls\n", dump_path, id);
    else
        qWarning("Breakpad: Dump failed\n");
    return succeeded;
}
#endif

// ============================================================================
//  MAIN FUNCTION
// ============================================================================
int main(int argc, char *argv[])
{
    // 1. 註冊 Windows 崩潰攔截器 (最優先)
#ifdef Q_OS_WIN
    SetUnhandledExceptionFilter(MyUnhandledExceptionFilter);
#endif

    // 2. 初始化 Breakpad (如果編譯環境支援)
#if defined(WIN32) && defined(_MSC_VER)
    QDir dir;
    if (!dir.exists("dmp"))
        dir.mkdir("dmp"); // 自動建立 dmp 資料夾
    ExceptionHandler eh(L"./dmp", nullptr, callback, nullptr, ExceptionHandler::HANDLER_ALL);
#endif

    // 3. High DPI 適配 (必須在 QApplication 創建前設定)
#if QT_VERSION >= QT_VERSION_CHECK(5, 6, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QCoreApplication::setAttribute(Qt::AA_UseHighDpiPixmaps);
#endif

#ifdef ANDROID
    AndroidAssets::copyAssetsToWritableLocation();
#endif

    // ========================================================================
    //  SECTION 3: AI Headless Mode (無介面訓練模式)
    // ========================================================================
    // 啟動參數： -ai_test
    bool is_ai_test = false;
    for (int i = 1; i < argc; i++)
    {
        if (strcmp(argv[i], "-ai_test") == 0)
        {
            is_ai_test = true;
            break;
        }
    }

    if (is_ai_test)
    {
        // 使用 QCoreApplication，不載入圖形資源，節省大量記憶體
        QCoreApplication app(argc, argv);

        // 初始化隨機數 (每個進程必須不同，否則結果會一樣)
        // 使用時間 + 物件地址作為種子
        qsrand(QTime::currentTime().msec() + (uintptr_t)&app);

        // 初始化核心引擎
        Sanguosha = new Engine;
        Config.init();

        // 強制極速設定
        Config.AIDelay = 0;
        Config.OriginAIDelay = 0;
        Config.OperationTimeout = 0;
        Config.OperationNoLimit = true;
        Config.EnableCheat = true; // 允許 AI 使用 cheat 指令(如果需要)

        BanPair::loadBanPairs();

        // 建立房間 (模式可以寫死或從參數讀取，這裡範例用 08p)
        // 注意：這裡 parent 設為 null，因為沒有 MainWindow
        Room *room = new Room(nullptr, "08p");

        // 填入 Robot (繞過 Socket)
        int playerCount = Sanguosha->getPlayerCount(room->getMode());
        for (int i = 0; i < playerCount; i++)
        {
            ServerPlayer *robot = new ServerPlayer(room);
            robot->setState("robot");
            // 給機器人隨機選將或固定選將
            room->signup(robot, QString("Bot_%1").arg(i), "sujiang", true);
        }

        // 連接結束信號，跑完自動關閉
        QObject::connect(room, SIGNAL(game_over(QString)), &app, SLOT(quit()));
        // 如果你有使用新語法：
        // QObject::connect(room, &Room::game_over, [&](const QString &winner){
        //     printf("[RESULT] Winner:%s\n", qPrintable(winner));
        //     app.quit();
        // });

        // 開始
        printf("[INFO] AI Simulation Started...\n");
        room->startGame();

        return app.exec();
    }

    // ========================================================================
    //  SECTION 4: 標準 GUI 模式 (Server / Client)
    // ========================================================================

    QScopedPointer<QCoreApplication> app;

    if (argc > 1 && strcmp(argv[1], "-server") == 0)
        app.reset(new QCoreApplication(argc, argv));
    else if (argc > 1 && strcmp(argv[1], "-manual") == 0)
    {
        app.reset(new QCoreApplication(argc, argv));
        Sanguosha = new Engine(true); // 手冊模式
        return 0;
    }
    else
    {
        app.reset(new QApplication(argc, argv)); // 正常遊戲模式
    }

    // 設定插件路徑
    QCoreApplication::addLibraryPath(QCoreApplication::applicationDirPath() + "/plugins");

    // 平台特定路徑修正
#ifdef Q_OS_MAC
#ifdef QT_NO_DEBUG
    QDir::setCurrent(qApp->applicationDirPath());
#endif
#endif

#ifdef Q_OS_LINUX
    static QDir dir("lua");
    if (!dir.exists() || !dir.exists("config.lua"))
    {
        QDir::setCurrent(qApp->applicationFilePath().replace("games", "share"));
    }
#endif

    // 初始化隨機數
    qsrand(QTime(0, 0, 0).secsTo(QTime::currentTime()));

    // 載入翻譯
    QTranslator qt_translator, translator;
    if (qt_translator.load("qt_zh_CN.qm"))
        qApp->installTranslator(&qt_translator);
    if (translator.load("sanguosha.qm"))
        qApp->installTranslator(&translator);

    // 初始化引擎與設定
    Sanguosha = new Engine;
    Config.init();

    // 設定字型 (僅 GUI 模式)
    if (qobject_cast<QApplication *>(qApp))
    {
        static_cast<QApplication *>(qApp)->setFont(Config.AppFont);
    }

    BanPair::loadBanPairs();

    // ---------------- SERVER 模式邏輯 ----------------
    if (qApp->arguments().contains("-server"))
    {
        Server *server = new Server(qApp);
        printf("Server is starting on port %u\n", Config.ServerPort);

        if (server->listen())
            printf("Starting successfully\n");
        else
        {
            delete server;
            printf("Starting failed!\n");
            return 0;
        }
        return qApp->exec();
    }

    // ---------------- CLIENT 模式邏輯 ----------------

    // 載入樣式表
    QFile file("qss/sanguosha.qss");
    if (file.open(QIODevice::ReadOnly))
    {
        QTextStream stream(&file);
        // stream.setCodec("UTF-8"); // 如果 QSS 有中文註解建議加上
        if (qobject_cast<QApplication *>(qApp))
        {
            static_cast<QApplication *>(qApp)->setStyleSheet(stream.readAll());
        }
    }

    // 創建主視窗
    // 使用 QScopedPointer 確保安全析構
    MainWindow *main_window = new MainWindow;

    // 引擎掛載到主視窗，隨視窗銷毀
    Sanguosha->setParent(main_window);

    main_window->show();

    // 音訊系統初始化
#ifdef AUDIO_SUPPORT
    Audio::init();
    Config.FrontBGMVolume = Config.value("FrontBGMVolume", 1.0f).toFloat();
    if (Config.FrontBGMVolume > 0.0001f && QFile::exists("audio/system/BGM/front-bgm.ogg"))
    {
        Audio::playBGM("audio/system/BGM/front-bgm.ogg");
        Audio::setBGMVolume(Config.FrontBGMVolume);
    }
#endif

    // 處理連接參數 (例如從大廳啟動)
    // 使用現代 range-based for loop
    for (const QString &arg : qApp->arguments())
    {
        if (arg.startsWith("-connect:"))
        {
            QString host = arg;
            host.remove("-connect:");
            Config.HostAddress = host;
            Config.setValue("HostAddress", host);

            main_window->startConnection();
            break;
        }
    }

    return qApp->exec();
}