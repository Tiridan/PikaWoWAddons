# PikaWoW Addons

Аддоны и доработки для WoW WotLK 3.3.5a (Interface 30300). Снимок от 20 ноября 2026 года. Часть функций рассчитана на сервер PikaWoW / Solo Progress и серверные команды Playerbot.

## Скачать и установить

Выберите нужный ZIP в таблице ниже. На странице файла нажмите **Download raw file**. Распакуйте папку аддона в **World of Warcraft/Interface/AddOns/**: файл `.toc` должен лежать непосредственно внутри папки с именем аддона. После установки новой папки полностью перезапустите игру и включите модификацию в списке аддонов. При обновлении сохраните папку WTF и свои SavedVariables.

Устанавливать весь комплект не требуется. Для TradeskillInfoUI нужен TradeskillInfo. AuctionMog требует отдельно установленные Auctionator и transmogTip; FishingMapSetup — GatherMate и GatherMate_Data. Необязательные интеграции перечислены в [каталоге](CATALOG.json) и в TOC каждого аддона. Для TomTom/FishingBuddy с суффиксом WDM1 обновлена библиотека карт: совместимость с вашим клиентским патчем карт следует проверять отдельно.

UnBot Custom включён в общий комплект: [исходники](AddOns/UnBotCustom), [ZIP](downloads/UnBotCustom-6.44.10-public.1.zip), [установка и перенос настроек](docs/UnBotCustom/INSTALL_RU.txt), [патчнота](docs/UnBotCustom/PATCH_NOTES_RU.txt). Перед включением Custom отключите обычный UnBot. Отдельный репозиторий [Tiridan/UnBotCustom](https://github.com/Tiridan/UnBotCustom) также сохранён. Публичная версия не содержит личных привязок аккаунтов; общая база обычных ботов сохранена.

## Наши аддоны и доработки

Исходники находятся в [AddOns](AddOns), готовые архивы — в [downloads](downloads).

| Аддон | Версия | Назначение | Скачать |
| --- | --- | --- | --- |
| UnBot Custom | 6.44.10-public.1 | Управление ботами и альтами, наборы экипировки и талантов, сбор групп и помощники. | [ZIP](downloads/UnBotCustom-6.44.10-public.1.zip) |
| AuctionMog | 1.2.1 | Галочка «Новый трансмог» в стандартном аукционе. | [ZIP](downloads/AuctionMog-1.2.1.zip) |
| BagBin | 1.12.0 | Очистка дешёвого хлама по цене полного стака. /bagbin | [ZIP](downloads/BagBin-1.12.0.zip) |
| ChatTimestamps | 1.0.1 | Добавляет настраиваемое локальное время к сообщениям чата. | [ZIP](downloads/ChatTimestamps-1.0.1.zip) |
| CursorHalo | 1.0.1 | Постоянная контрастная метка вокруг курсора для WotLK 3.3.5a. | [ZIP](downloads/CursorHalo-1.0.1.zip) |
| DarkmoonDeckTracker | 1.0.1 | Показывает карты Новолуния, недостающие карты и награды за колоды. | [ZIP](downloads/DarkmoonDeckTracker-1.0.1.zip) |
| DungeonSeeker | 1.1.6 | Две кнопки для входа/выхода и выбор конкретного подземелья. | [ZIP](downloads/DungeonSeeker-1.1.6.zip) |
| FishingMapSetup | 1.0 | Импортирует базу рыбных мест GatherMate и включает значки рыбалки на карте. | [ZIP](downloads/FishingMapSetup-1.0.zip) |
| PikaBankViewer | 0.3.13 | Сохранённый личный банк и хранилище Ling с категориями. | [ZIP](downloads/PikaBankViewer-0.3.13.zip) |
| ProfessionPath | 1.2.5 | Прогресс профессий, маршруты, помощь с заданиями и отслеживание ресурсов. | [ZIP](downloads/ProfessionPath-1.2.5.zip) |
| SoloProgressGuide | 0.8.31 | Персональный путеводитель по открытию контента Solo Progress | [ZIP](downloads/SoloProgressGuide-0.8.31.zip) |
| ThoriumBrotherhoodGuide | 1.0.5 | Пошаговый помощник по репутации Братства Тория | [ZIP](downloads/ThoriumBrotherhoodGuide-1.0.5.zip) |
| TriageHelper | 1.0.1 | Подсвечивает пациентов по порядку оказания помощи в заданиях 6622/6624. | [ZIP](downloads/TriageHelper-1.0.1.zip) |
| UnBotRetHelper | 1.0.3 | Secure manual helper panel for Retribution Paladin (WotLK 3.3.5a) | [ZIP](downloads/UnBotRetHelper-1.0.3.zip) |
| UnBotTrace | 1.2.0 | Readable summon diagnostics and an explicit registry command sweep for screen recording. | [ZIP](downloads/UnBotTrace-1.2.0.zip) |

## Доработанные сторонние сборки

Архивы содержат полные установочные папки, исходники, ресурсы и комплектные библиотеки. Авторы исходных проектов и уведомления в файлах сохранены. Это снимки используемых доработанных версий, а не новые версии от исходных авторов.

| Аддон | Версия | Назначение | Скачать |
| --- | --- | --- | --- |
| ArkInventory | 3.02.46-Compat.4 | Allows viewing of your (and your alts) Bags, Keyring, Bank, Guild Bank, Inventory and Mail items when ever and where ever you want. | [ZIP](downloads/ArkInventory-3.02.46-Compat.4.zip) |
| CompactRaidFrame | 1.2.3 | backport Blizzard raid frames from retail. | [ZIP](downloads/CompactRaidFrame-1.2.3.zip) |
| DialogUI | 1.0.8 | Addon made for an immersive questing experience, ported to WotLK 3.3.5a. Consider it a Vanilla+ frame. | [ZIP](downloads/DialogUI-1.0.8.zip) |
| Molinari | 30300.6-Ark.2 | Alt-click disenchanting, milling and prospecting. ArkInventory support. | [ZIP](downloads/Molinari-30300.6-Ark.2.zip) |
| Routes | v1.2.8a-Compat.1 | Routes on your worldmap and minimap! | [ZIP](downloads/Routes-v1.2.8a-Compat.1.zip) |
| TradeskillInfo | 1.6.1-WotLK.1 | Complete Tradeskill Info | [ZIP](downloads/TradeskillInfo-1.6.1-WotLK.1.zip) |
| TradeskillInfoUI | 1.6.1-WotLK.1 | Complete Tradeskill Info UI | [ZIP](downloads/TradeskillInfoUI-1.6.1-WotLK.1.zip) |
| TomTom | wowi:revision-WDM1 | Удобный портативный навигатор по игровой карте | [ZIP](downloads/TomTom-wowi_revision-WDM1.zip) |
| FishingBuddy | 0.9.8p1-WDM1 | Help with fishing related tasks -- clothing, fish information, etc. | [ZIP](downloads/FishingBuddy-0.9.8p1-WDM1.zip) |

## Состав и проверка

Включены только исходники и ресурсы аддонов. Пользовательские SavedVariables, логи, резервные копии и рабочая документация исключены. UnBotMarket остаётся приватным и в поставку не входит. Неизменённые сторонние аддоны не перепубликуются. BossMemory уже встроен в UnBot Custom; старый импортёр не поставляется как самостоятельный аддон.

Проверен синтаксис 434 Lua-файлов в режиме Lua 5.1, CRC архивов и побайтовое совпадение их содержимого с подготовленным снимком. Это проверка публикации; она не заменяет проверку каждой функции в игре. Точные версии, авторы и зависимости: [CATALOG.json](CATALOG.json). Контрольные суммы: [SHA256SUMS.txt](SHA256SUMS.txt).

Лицензии отдельных проектов и библиотек сохраняются в их файлах. Общая новая лицензия на весь комплект не назначается.
