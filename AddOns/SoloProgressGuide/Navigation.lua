local G=SoloProgressGuide
-- Coordinates from installed Questie-335 databases; outdoor map points only.
G.mapNPCs={}
G.mapQuests={}
G.mapNPCs["Classic:344"]={{name="Мировой судья Соломон",zone="Красногорье",zoneEN="Redridge Mountains",x=29.99,y=44.45,patrol=false}}
G.mapNPCs["Classic:1748"]={{name="Верховный лорд Болвар Фордрагон",zone="Штормград",zoneEN="Stormwind City",x=78.23,y=17.98,patrol=false}}
G.mapNPCs["Classic:4949"]={{name="Тралл",zone="Оргриммар",zoneEN="Orgrimmar",x=31.73,y=37.82,patrol=false}}
G.mapNPCs["Classic:7996"]={{name="Квиага Хранительница",zone="Внутренние земли",zoneEN="The Hinterlands",x=48.64,y=68.24,patrol=false}}
G.mapNPCs["Classic:8125"]={{name="Могиль Быстроруб",zone="Танарис",zoneEN="Tanaris",x=52.63,y=28.11,patrol=false}}
G.mapNPCs["Classic:9560"]={{name="Маршал Максвелл",zone="Пылающие степи",zoneEN="Burning Steppes",x=84.74,y=69.02,patrol=false}}
G.mapNPCs["Classic:9562"]={{name="Хелендис Речной Мыс",zone="Пылающие степи",zoneEN="Burning Steppes",x=85.82,y=68.95,patrol=false}}
G.mapNPCs["Classic:10182"]={{name="Рексар",zone="Фералас",zoneEN="Feralas",x=45.02,y=9.09,patrol=true},{name="Рексар",zone="Когтистые горы",zoneEN="Stonetalon Mountains",x=30.18,y=75.5,patrol=true},{name="Рексар",zone="Пустоши",zoneEN="Desolace",x=48.27,y=57.51,patrol=true}}
G.mapNPCs["Classic:10321"]={{name="Огнебор",zone="Пылевые топи",zoneEN="Dustwallow Marsh",x=56.66,y=87.72,patrol=false}}
G.mapNPCs["Classic:10929"]={{name="Хале",zone="Зимние Ключи",zoneEN="Winterspring",x=54.55,y=51.2,patrol=false}}
G.mapNPCs["Classic:11811"]={{name="Нарайн Причудень",zone="Танарис",zoneEN="Tanaris",x=65.24,y=18.58,patrol=false}}
G.mapNPCs["Classic:11832"]={{name="Хранитель Ремул",zone="Лунная поляна",zoneEN="Moonglade",x=36.18,y=41.79,patrol=false}}
G.mapNPCs["Classic:11872"]={{name="Миранда Колдунья",zone="Западные Чумные земли",zoneEN="Western Plaguelands",x=50.79,y=77.85,patrol=false}}
G.mapNPCs["Classic:13278"]={{name="Герцог Гидраксис",zone="Азшара",zoneEN="Azshara",x=79.28,y=73.7,patrol=false}}
G.mapNPCs["Classic:15180"]={{name="Баристолф из Зыбучих Песков",zone="Силитус",zoneEN="Silithus",x=49.45,y=36.45,patrol=false}}
G.mapNPCs["Classic:15192"]={{name="Анахронос",zone="Танарис",zoneEN="Tanaris",x=65.27,y=50.03,patrol=false}}
G.mapNPCs["Classic:15481"]={{name="Дух Азурегоса — маршрут патруля",zone="Азшара",zoneEN="Azshara",x=54.38,y=79.79,patrol=true}}
G.mapNPCs["Classic:15526"]={{name="Мередит Русалла",zone="Танарис",zoneEN="Tanaris",x=59.43,y=96.05,patrol=false}}
G.mapNPCs["Classic:15693"]={{name="Джонатан Богослов",zone="Силитус",zoneEN="Silithus",x=25.94,y=90.96,patrol=false}}
G.mapNPCs["Classic:16116"]={{name="Верховный маг Анжела Досантос",zone="Восточные Чумные земли",zoneEN="Eastern Plaguelands",x=81.52,y=58.27,patrol=false}}
G.mapQuests["Classic:7848"]={"Classic:14387"}
G.mapQuests["Classic:4903"]={"Classic:9077"}
G.mapQuests["Classic:4941"]={"Classic:9077","Classic:4949"}
G.mapQuests["Classic:4974"]={"Classic:4949"}
G.mapQuests["Classic:6566"]={"Classic:4949"}
G.mapQuests["Classic:6567"]={"Classic:4949","Classic:10182"}
G.mapQuests["Classic:6568"]={"Classic:10182","Classic:11872"}
G.mapQuests["Classic:6569"]={"Classic:11872"}
G.mapQuests["Classic:6570"]={"Classic:11872","Classic:10321"}
G.mapQuests["Classic:6584"]={"Classic:10321"}
G.mapQuests["Classic:6582"]={"Classic:10321"}
G.mapQuests["Classic:6583"]={"Classic:10321"}
G.mapQuests["Classic:6585"]={"Classic:10321"}
G.mapQuests["Classic:6601"]={"Classic:10321","Classic:10182"}
G.mapQuests["Classic:6602"]={"Classic:10182"}
G.mapQuests["Classic:4182"]={"Classic:9562"}
G.mapQuests["Classic:4183"]={"Classic:9562","Classic:344"}
G.mapQuests["Classic:4184"]={"Classic:344","Classic:1748"}
G.mapQuests["Classic:4185"]={"Classic:1748"}
G.mapQuests["Classic:4186"]={"Classic:1748","Classic:344"}
G.mapQuests["Classic:4223"]={"Classic:344","Classic:9560"}
G.mapQuests["Classic:4224"]={"Classic:9560"}
G.mapQuests["Classic:4241"]={"Classic:9560","Classic:9023"}
G.mapQuests["Classic:4242"]={"Classic:9023","Classic:9560"}
G.mapQuests["Classic:4264"]={"Classic:9023"}
G.mapQuests["Classic:4282"]={"Classic:9023"}
G.mapQuests["Classic:4322"]={"Classic:9023","Classic:9560"}
G.mapQuests["Classic:6402"]={"Classic:9560","Classic:12580"}
G.mapQuests["Classic:6403"]={"Classic:12580","Classic:1748"}
G.mapQuests["Classic:6501"]={"Classic:1748","Classic:10929"}
G.mapQuests["Classic:6502"]={"Classic:10929"}
G.mapQuests["Classic:7761"]={}
G.mapQuests["Classic:9121"]={"Classic:16116"}
G.mapQuests["Classic:9122"]={"Classic:16116"}
G.mapQuests["Classic:9123"]={"Classic:16116"}
G.mapQuests["Classic:6804"]={"Classic:13278"}
G.mapQuests["Classic:6805"]={"Classic:13278"}
G.mapQuests["Classic:6821"]={"Classic:13278"}
G.mapQuests["Classic:6822"]={"Classic:13278"}
G.mapQuests["Classic:6823"]={"Classic:13278"}
G.mapQuests["Classic:6824"]={"Classic:13278"}
G.mapQuests["Classic:7486"]={"Classic:13278"}
G.mapQuests["Classic:8286"]={"Classic:15180"}
G.mapQuests["Classic:8288"]={"Classic:15180"}
G.mapQuests["Classic:8301"]={"Classic:15180"}
G.mapQuests["Classic:8303"]={"Classic:15180","Classic:15192"}
G.mapQuests["Classic:8305"]={"Classic:15192"}
G.mapQuests["Classic:8519"]={"Classic:15192"}
G.mapQuests["Classic:8555"]={"Classic:15192"}
G.mapQuests["Classic:8730"]={"Classic:13020","Classic:15192"}
G.mapQuests["Classic:8733"]={"Classic:15362","Classic:15624"}
G.mapQuests["Classic:8734"]={"Classic:15624","Classic:11832"}
G.mapQuests["Classic:8735"]={"Classic:11832"}
G.mapQuests["Classic:8736"]={"Classic:11832"}
G.mapQuests["Classic:8741"]={"Classic:11832","Classic:15192"}
G.mapQuests["Classic:8575"]={"Classic:15481","Classic:11811"}
G.mapQuests["Classic:8576"]={"Classic:11811"}
G.mapQuests["Classic:8597"]={"Classic:11811"}
G.mapQuests["Classic:8599"]={"Classic:15526","Classic:11811"}
G.mapQuests["Classic:8598"]={"Classic:11811"}
G.mapQuests["Classic:8606"]={"Classic:11811"}
G.mapQuests["Classic:8620"]={"Classic:11811"}
G.mapQuests["Classic:8584"]={"Classic:11811","Classic:8125"}
G.mapQuests["Classic:8585"]={"Classic:8125"}
G.mapQuests["Classic:8586"]={"Classic:8125"}
G.mapQuests["Classic:8587"]={"Classic:8125","Classic:11811"}
G.mapQuests["Classic:8577"]={"Classic:11811"}
G.mapQuests["Classic:8578"]={"Classic:11811"}
G.mapQuests["Classic:8728"]={"Classic:11811"}
G.mapQuests["Classic:8729"]={"Classic:11811","Classic:15192"}
G.mapQuests["Classic:8742"]={"Classic:15192"}
G.mapQuests["Classic:8745"]={"Classic:15693"}
G.mapNPCs["Wotlk:344"]={{name="Мировой судья Соломон",zone="Красногорье",zoneEN="Redridge Mountains",x=29.99,y=44.45,patrol=false}}
G.mapNPCs["Wotlk:4949"]={{name="Тралл",zone="Оргриммар",zoneEN="Orgrimmar",x=31.61,y=37.83,patrol=false}}
G.mapNPCs["Wotlk:7996"]={{name="Квиага Хранительница",zone="Внутренние земли",zoneEN="The Hinterlands",x=48.65,y=68.25,patrol=false}}
G.mapNPCs["Wotlk:8125"]={{name="Могиль Быстроруб",zone="Танарис",zoneEN="Tanaris",x=52.63,y=28.11,patrol=false}}
G.mapNPCs["Wotlk:9077"]={{name="Полководец Клинозуб",zone="Бесплодные земли",zoneEN="Badlands",x=5.81,y=47.52,patrol=false}}
G.mapNPCs["Wotlk:9560"]={{name="Маршал Максвелл",zone="Пылающие степи",zoneEN="Burning Steppes",x=84.74,y=69.02,patrol=false}}
G.mapNPCs["Wotlk:10321"]={{name="Огнебор",zone="Пылевые топи",zoneEN="Dustwallow Marsh",x=56.66,y=87.72,patrol=false}}
G.mapNPCs["Wotlk:10929"]={{name="Хале",zone="Зимние Ключи",zoneEN="Winterspring",x=54.55,y=51.2,patrol=false}}
G.mapNPCs["Wotlk:11811"]={{name="Нарайн Причудень",zone="Танарис",zoneEN="Tanaris",x=65.24,y=18.58,patrol=false}}
G.mapNPCs["Wotlk:11832"]={{name="Хранитель Ремул",zone="Лунная поляна",zoneEN="Moonglade",x=36.18,y=41.79,patrol=false}}
G.mapNPCs["Wotlk:11872"]={{name="Миранда Колдунья",zone="Западные Чумные земли",zoneEN="Western Plaguelands",x=50.79,y=77.85,patrol=false}}
G.mapNPCs["Wotlk:13278"]={{name="Герцог Гидраксис",zone="Азшара",zoneEN="Azshara",x=79.28,y=73.7,patrol=false}}
G.mapNPCs["Wotlk:15180"]={{name="Баристолф из Зыбучих Песков",zone="Силитус",zoneEN="Silithus",x=49.45,y=36.45,patrol=false}}
G.mapNPCs["Wotlk:15192"]={{name="Анахронос",zone="Танарис",zoneEN="Tanaris",x=64.2,y=51.42,patrol=false}}
G.mapNPCs["Wotlk:15481"]={{name="Дух Азурегоса — маршрут патруля",zone="Азшара",zoneEN="Azshara",x=54.38,y=79.79,patrol=true}}
G.mapNPCs["Wotlk:15526"]={{name="Мередит Русалла",zone="Танарис",zoneEN="Tanaris",x=59.43,y=96.05,patrol=false}}
G.mapNPCs["Wotlk:15693"]={{name="Джонатан Богослов",zone="Силитус",zoneEN="Silithus",x=25.94,y=90.96,patrol=false}}
G.mapNPCs["Wotlk:16116"]={{name="Верховный маг Анжела Досантос",zone="Восточные Чумные земли",zoneEN="Eastern Plaguelands",x=75.75,y=52.4,patrol=false}}
G.mapNPCs["Wotlk:17636"]={{name="Калинна Латред",zone="Пустоверть",zoneEN="Netherstorm",x=32.22,y=63.6,patrol=false}}
G.mapNPCs["Wotlk:18166"]={{name="Кадгар",zone="Шаттрат",zoneEN="Shattrath City",x=54.75,y=44.32,patrol=false}}
G.mapNPCs["Wotlk:18481"]={{name="А'дал",zone="Шаттрат",zoneEN="Shattrath City",x=53.99,y=44.75,patrol=false}}
G.mapNPCs["Wotlk:18528"]={{name="Зи'ри",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=65.22,y=43.96,patrol=false}}
G.mapNPCs["Wotlk:20130"]={{name="Андорму",zone="Танарис",zoneEN="Tanaris",x=58.43,y=54.28,patrol=false}}
G.mapNPCs["Wotlk:20142"]={{name="Распорядитель времени",zone="Танарис",zoneEN="Tanaris",x=66.02,y=49.7,patrol=false}}
G.mapNPCs["Wotlk:21024"]={{name="Целитель земли Торлок",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=42.19,y=45.06,patrol=false}}
G.mapNPCs["Wotlk:21183"]={{name="Оронок Горемычный",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=53.95,y=23.52,patrol=false}}
G.mapNPCs["Wotlk:21292"]={{name="Ар'тор, сын Оронока",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=29.63,y=50.4,patrol=false}}
G.mapNPCs["Wotlk:21293"]={{name="Борак, сын Оронока",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=47.56,y=57.18,patrol=false}}
G.mapNPCs["Wotlk:21318"]={{name="Дух Ар'тора",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=29.54,y=50.56,patrol=false}}
G.mapNPCs["Wotlk:21402"]={{name="Анахоретка Сейла",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=62.58,y=28.38,patrol=false}}
G.mapNPCs["Wotlk:21700"]={{name="Акама",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=58.11,y=48.18,patrol=false}}
G.mapNPCs["Wotlk:21826"]={{name="Санору",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=57.33,y=49.58,patrol=false}}
G.mapNPCs["Wotlk:21937"]={{name="Целитель земли Софурус",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=36.37,y=56.95,patrol=false}}
G.mapNPCs["Wotlk:21938"]={{name="Целитель земли Расщепленное копыто",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=28.49,y=26.57,patrol=false}}
G.mapNPCs["Wotlk:21955"]={{name="Чародей Тэлис",zone="Долина Призрачной Луны",zoneEN="Shadowmoon Valley",x=56.25,y=59.6,patrol=false}}
G.mapNPCs["Wotlk:24813"]={{name="Экзарх Ларетор",zone="Остров Кель’Данас",zoneEN="Isle of Quel'Danas",x=47.42,y=30.74,patrol=false}}
G.mapNPCs["Wotlk:26917"]={{name="Алекстраза Хранительница Жизни",zone="Драконий Погост",zoneEN="Dragonblight",x=59.83,y=54.66,patrol=false}}
G.mapQuests["Wotlk:7848"]={"Wotlk:14387"}
G.mapQuests["Wotlk:4903"]={"Wotlk:9077"}
G.mapQuests["Wotlk:4941"]={"Wotlk:9077","Wotlk:4949"}
G.mapQuests["Wotlk:4974"]={"Wotlk:4949"}
G.mapQuests["Wotlk:6566"]={"Wotlk:4949"}
G.mapQuests["Wotlk:6567"]={"Wotlk:4949","Wotlk:10182"}
G.mapQuests["Wotlk:6568"]={"Wotlk:10182","Wotlk:11872"}
G.mapQuests["Wotlk:6569"]={"Wotlk:11872"}
G.mapQuests["Wotlk:6570"]={"Wotlk:11872","Wotlk:10321"}
G.mapQuests["Wotlk:6584"]={"Wotlk:10321"}
G.mapQuests["Wotlk:6582"]={"Wotlk:10321"}
G.mapQuests["Wotlk:6583"]={"Wotlk:10321"}
G.mapQuests["Wotlk:6585"]={"Wotlk:10321"}
G.mapQuests["Wotlk:6601"]={"Wotlk:10321","Wotlk:10182"}
G.mapQuests["Wotlk:6602"]={"Wotlk:10182"}
G.mapQuests["Wotlk:4182"]={}
G.mapQuests["Wotlk:4183"]={}
G.mapQuests["Wotlk:4184"]={}
G.mapQuests["Wotlk:4185"]={}
G.mapQuests["Wotlk:4186"]={}
G.mapQuests["Wotlk:4223"]={"Wotlk:344","Wotlk:9560"}
G.mapQuests["Wotlk:4224"]={"Wotlk:9560"}
G.mapQuests["Wotlk:4241"]={"Wotlk:9560","Wotlk:9023"}
G.mapQuests["Wotlk:4242"]={"Wotlk:9023","Wotlk:9560"}
G.mapQuests["Wotlk:4264"]={"Wotlk:9023"}
G.mapQuests["Wotlk:4282"]={"Wotlk:9023"}
G.mapQuests["Wotlk:4322"]={"Wotlk:9023","Wotlk:9560"}
G.mapQuests["Wotlk:6402"]={"Wotlk:9560","Wotlk:12580"}
G.mapQuests["Wotlk:6403"]={"Wotlk:12580","Wotlk:1748"}
G.mapQuests["Wotlk:6501"]={"Wotlk:1748","Wotlk:10929"}
G.mapQuests["Wotlk:6502"]={"Wotlk:10929"}
G.mapQuests["Wotlk:7761"]={}
G.mapQuests["Wotlk:9121"]={"Wotlk:16116"}
G.mapQuests["Wotlk:9122"]={"Wotlk:16116"}
G.mapQuests["Wotlk:9123"]={"Wotlk:16116"}
G.mapQuests["Wotlk:6804"]={"Wotlk:13278"}
G.mapQuests["Wotlk:6805"]={"Wotlk:13278"}
G.mapQuests["Wotlk:6821"]={"Wotlk:13278"}
G.mapQuests["Wotlk:6822"]={"Wotlk:13278"}
G.mapQuests["Wotlk:6823"]={"Wotlk:13278"}
G.mapQuests["Wotlk:6824"]={"Wotlk:13278"}
G.mapQuests["Wotlk:7486"]={"Wotlk:13278"}
G.mapQuests["Wotlk:9630"]={"Wotlk:17613","Wotlk:16813"}
G.mapQuests["Wotlk:9638"]={"Wotlk:16813","Wotlk:16814"}
G.mapQuests["Wotlk:9639"]={"Wotlk:16814","Wotlk:16815"}
G.mapQuests["Wotlk:9640"]={"Wotlk:16815"}
G.mapQuests["Wotlk:9645"]={"Wotlk:16815","Wotlk:17613"}
G.mapQuests["Wotlk:9680"]={"Wotlk:17613"}
G.mapQuests["Wotlk:9631"]={"Wotlk:17613","Wotlk:17636"}
G.mapQuests["Wotlk:9637"]={"Wotlk:17636"}
G.mapQuests["Wotlk:9644"]={"Wotlk:17636","Wotlk:17613"}
G.mapQuests["Wotlk:13372"]={"Wotlk:26917"}
G.mapQuests["Wotlk:9824"]={"Wotlk:17613"}
G.mapQuests["Wotlk:9825"]={"Wotlk:17613"}
G.mapQuests["Wotlk:9826"]={"Wotlk:17613","Wotlk:18165"}
G.mapQuests["Wotlk:9829"]={"Wotlk:18165","Wotlk:18166"}
G.mapQuests["Wotlk:9831"]={"Wotlk:18166"}
G.mapQuests["Wotlk:9832"]={"Wotlk:18166"}
G.mapQuests["Wotlk:9836"]={"Wotlk:18166","Wotlk:15608"}
G.mapQuests["Wotlk:9837"]={"Wotlk:15608","Wotlk:18166"}
G.mapQuests["Wotlk:9838"]={"Wotlk:18166","Wotlk:17613"}
G.mapQuests["Wotlk:10681"]={"Wotlk:21938","Wotlk:21024"}
G.mapQuests["Wotlk:10458"]={"Wotlk:21024"}
G.mapQuests["Wotlk:10480"]={"Wotlk:21024"}
G.mapQuests["Wotlk:10481"]={"Wotlk:21024"}
G.mapQuests["Wotlk:10513"]={"Wotlk:21024","Wotlk:21183"}
G.mapQuests["Wotlk:10514"]={"Wotlk:21183"}
G.mapQuests["Wotlk:10515"]={"Wotlk:21183"}
G.mapQuests["Wotlk:10519"]={"Wotlk:21183"}
G.mapQuests["Wotlk:10521"]={"Wotlk:21183","Wotlk:21291"}
G.mapQuests["Wotlk:10527"]={"Wotlk:21183","Wotlk:21292"}
G.mapQuests["Wotlk:10546"]={"Wotlk:21183","Wotlk:21293"}
G.mapQuests["Wotlk:10522"]={"Wotlk:21291"}
G.mapQuests["Wotlk:10528"]={"Wotlk:21292"}
G.mapQuests["Wotlk:10547"]={"Wotlk:21293","Wotlk:21411"}
G.mapQuests["Wotlk:10523"]={"Wotlk:21291","Wotlk:21183"}
G.mapQuests["Wotlk:10537"]={"Wotlk:21318"}
G.mapQuests["Wotlk:10550"]={"Wotlk:21411","Wotlk:21293"}
G.mapQuests["Wotlk:10540"]={"Wotlk:21318"}
G.mapQuests["Wotlk:10570"]={"Wotlk:21293"}
G.mapQuests["Wotlk:10576"]={"Wotlk:21293"}
G.mapQuests["Wotlk:10577"]={"Wotlk:21293"}
G.mapQuests["Wotlk:10578"]={"Wotlk:21293"}
G.mapQuests["Wotlk:10541"]={"Wotlk:21318","Wotlk:21183"}
G.mapQuests["Wotlk:10579"]={"Wotlk:21293","Wotlk:21183"}
G.mapQuests["Wotlk:10588"]={"Wotlk:21183","Wotlk:21024"}
G.mapQuests["Wotlk:10883"]={"Wotlk:18166","Wotlk:18481"}
G.mapQuests["Wotlk:10884"]={"Wotlk:18481"}
G.mapQuests["Wotlk:10885"]={"Wotlk:18481"}
G.mapQuests["Wotlk:10886"]={"Wotlk:18481"}
G.mapQuests["Wotlk:10888"]={}
G.mapQuests["Wotlk:13375"]={"Wotlk:26917"}
G.mapQuests["Wotlk:10568"]={"Wotlk:21402"}
G.mapQuests["Wotlk:10683"]={"Wotlk:21955"}
G.mapQuests["Wotlk:10571"]={"Wotlk:21402"}
G.mapQuests["Wotlk:10684"]={"Wotlk:21955"}
G.mapQuests["Wotlk:10574"]={"Wotlk:21402"}
G.mapQuests["Wotlk:10685"]={"Wotlk:21955"}
G.mapQuests["Wotlk:10575"]={"Wotlk:21402","Wotlk:21826"}
G.mapQuests["Wotlk:10686"]={"Wotlk:21955","Wotlk:21826"}
G.mapQuests["Wotlk:10622"]={"Wotlk:21826"}
G.mapQuests["Wotlk:10628"]={"Wotlk:21826","Wotlk:21700"}
G.mapQuests["Wotlk:10705"]={"Wotlk:21700","Wotlk:21962"}
G.mapQuests["Wotlk:10706"]={"Wotlk:21962","Wotlk:21700"}
G.mapQuests["Wotlk:10707"]={"Wotlk:21700"}
G.mapQuests["Wotlk:10708"]={"Wotlk:21700","Wotlk:18481"}
G.mapQuests["Wotlk:10944"]={"Wotlk:22820","Wotlk:21700"}
G.mapQuests["Wotlk:10946"]={"Wotlk:21700"}
G.mapQuests["Wotlk:10947"]={"Wotlk:21700"}
G.mapQuests["Wotlk:10948"]={"Wotlk:21700","Wotlk:18481"}
G.mapQuests["Wotlk:10949"]={"Wotlk:18481","Wotlk:18528"}
G.mapQuests["Wotlk:10985"]={"Wotlk:18528"}
G.mapQuests["Wotlk:10901"]={}
G.mapQuests["Wotlk:10445"]={"Wotlk:19935"}
G.mapQuests["Wotlk:8286"]={"Wotlk:15180"}
G.mapQuests["Wotlk:8288"]={"Wotlk:15180"}
G.mapQuests["Wotlk:8301"]={"Wotlk:15180"}
G.mapQuests["Wotlk:8303"]={"Wotlk:15180","Wotlk:15192"}
G.mapQuests["Wotlk:8305"]={"Wotlk:15192"}
G.mapQuests["Wotlk:8519"]={"Wotlk:15192"}
G.mapQuests["Wotlk:8555"]={"Wotlk:15192"}
G.mapQuests["Wotlk:8730"]={"Wotlk:13020","Wotlk:15192"}
G.mapQuests["Wotlk:8733"]={"Wotlk:15362","Wotlk:15624"}
G.mapQuests["Wotlk:8734"]={"Wotlk:15624","Wotlk:11832"}
G.mapQuests["Wotlk:8735"]={"Wotlk:11832"}
G.mapQuests["Wotlk:8736"]={"Wotlk:11832"}
G.mapQuests["Wotlk:8741"]={"Wotlk:11832","Wotlk:15192"}
G.mapQuests["Wotlk:8575"]={"Wotlk:15481","Wotlk:11811"}
G.mapQuests["Wotlk:8576"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8597"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8599"]={"Wotlk:15526","Wotlk:11811"}
G.mapQuests["Wotlk:8598"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8606"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8620"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8584"]={"Wotlk:11811","Wotlk:8125"}
G.mapQuests["Wotlk:8585"]={"Wotlk:8125"}
G.mapQuests["Wotlk:8586"]={"Wotlk:8125"}
G.mapQuests["Wotlk:8587"]={"Wotlk:8125","Wotlk:11811"}
G.mapQuests["Wotlk:8577"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8578"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8728"]={"Wotlk:11811"}
G.mapQuests["Wotlk:8729"]={"Wotlk:11811","Wotlk:15192"}
G.mapQuests["Wotlk:8742"]={"Wotlk:15192"}
G.mapQuests["Wotlk:8745"]={"Wotlk:15693"}
G.mapQuests["Wotlk:10279"]={"Wotlk:20142","Wotlk:20130"}
G.mapQuests["Wotlk:10277"]={"Wotlk:20130"}
G.mapQuests["Wotlk:10282"]={"Wotlk:20130","Wotlk:18723"}
G.mapQuests["Wotlk:10283"]={"Wotlk:18723","Wotlk:17876"}
G.mapQuests["Wotlk:10284"]={"Wotlk:17876","Wotlk:18723"}
G.mapQuests["Wotlk:10285"]={"Wotlk:18723","Wotlk:20130"}
G.mapQuests["Wotlk:11481"]={"Wotlk:18537","Wotlk:24813"}
G.mapQuests["Wotlk:11488"]={"Wotlk:24813","Wotlk:24822"}
G.mapQuests["Wotlk:11490"]={"Wotlk:24822","Wotlk:24848"}
G.mapQuests["Wotlk:11492"]={"Wotlk:24848","Wotlk:24813"}
G.mapQuests["Wotlk:10680"]={"Wotlk:21937","Wotlk:21024"}

G.patrolRoutes={[10182]={[357]={{{46.39,18.25},{46.37,17.8},{46.35,17.35},{46.41,16.15},{46.46,15.61},{46.41,14.97},{46.34,14.29},{46.12,13.42},{45.98,12.82},{45.9,12.36},{45.87,11.85},{45.87,11.17},{45.85,10.83},{45.73,10.49},{45.35,9.8},{45.02,9.09},{44.91,8.8},{44.89,8.48},{44.9,7.75},{44.92,7.11},{44.98,6.9},{45.33,6.23},{45.66,5.56},{45.78,5.2},{45.86,4.86},{45.87,4.3},{45.82,3.98},{45.61,3.33},{45.54,3.04},{45.43,2.81},{45.12,2.53},{44.99,2.37}}},[406]={{{29.72,77.99},{29.91,77.59},{30.13,77.24},{30.2,76.88},{30.2,76.49},{30.18,75.97},{30.18,75.5},{30.22,75.1},{30.18,75.5},{30.18,75.97},{30.2,76.49},{30.2,76.88},{30.13,77.24},{29.91,77.59},{29.72,77.99}}},[405]={{{42.44,97.05},{42.27,96.49},{41.94,96.09},{41.71,95.62},{41.63,94.91},{41.56,94.04},{41.46,93.66},{41.28,93.38},{41.25,92.45},{41.17,91.74},{40.94,91.32},{40.89,90.82},{40.78,90.03},{40.63,89.49},{40.67,89.19},{40.9,88.46},{41.18,87.78},{41.38,87.28},{41.58,86.64},{41.8,85.89},{41.84,85.5},{41.76,85.13},{41.44,84.78},{41.07,84.18},{40.44,83.1},{39.96,82.29},{39.74,81.94},{39.71,81.42},{39.72,80.7},{39.66,79.83},{39.7,79.22},{39.86,78.65},{40.04,78.38},{40.26,78.33},{40.6,78.5},{40.88,78.51},{41.38,78.14},{41.8,78.01},{42.19,77.75},{42.98,76.84},{43.4,76.61},{44.04,76.56},{44.34,76.45},{44.63,76.11},{44.99,75.5},{45.38,75.19},{45.83,75.12},{46.92,75.12},{47.21,75.14},{47.74,75.42},{48.14,75.48},{48.65,75.78},{49,75.88},{49.48,75.64},{49.81,75.58},{50.14,75.59},{50.54,75.37},{50.85,75.02},{51.19,74.46},{51.45,73.72},{51.52,72.62},{51.57,72.13},{51.71,71.66},{51.86,70.92},{51.84,70.48},{51.7,69.9},{51.17,68.4},{50.62,67.01},{50.37,66.66},{49.65,65.71},{49.13,65.17},{48.89,64.66},{48.54,63.95},{48.34,63.37},{48.44,61.73},{48.49,61.35},{48.45,60.78},{48.35,60.26},{48.17,59.45},{48.21,58.86},{48.34,58.28},{48.33,57.89},{48.27,57.51},{48.36,57.05},{48.69,56.18},{49.1,55.19},{49.23,54.77},{49,53.79},{48.95,53.05},{48.97,51.94},{49.07,50.51},{49.32,49.23},{49.56,48.35},{49.63,47.7},{49.69,46.67},{49.71,45.46},{49.78,44.88},{49.91,44.2},{50.12,43.52},{50.63,41.96},{50.88,41.38},{51.4,40.58},{51.99,39.47},{52.4,38.63},{52.85,37.93},{53.2,37.54},{53.59,37.28},{53.99,37.17},{54.74,37.16},{55.62,37.3},{56.33,37.67},{57.06,38.13},{57.51,38.27},{58,38.24},{58.51,38.16},{59.28,37.91},{59.91,37.61},{60.3,37.3},{60.69,36.79},{60.98,36.08},{61.15,35.23},{61.31,34.05},{61.59,33.29},{62.11,32.3},{62.35,31.71},{62.56,30.85},{62.73,29.57},{62.92,28.57},{63.15,27.83},{63.34,27.13},{63.39,26.38},{63.33,25.76},{63.04,24.82},{63.01,24.03},{62.93,23.03},{62.71,22.13},{62.61,21.21},{62.53,20.26},{62.41,19.47},{62.2,18.89},{61.75,18.44},{61.33,18.07},{61.11,17.64},{60.78,16.66},{60.44,16.06},{60.07,15.69},{59.14,14.94},{58.69,14.59},{58.17,14.07},{57.79,13.7},{57.38,13.56},{56.69,13.45},{56.31,13.32},{55.93,12.87},{55.46,12.22},{54.96,11.6},{54.62,11.03},{54.23,10.09},{54.01,9},{53.86,8.26},{53.6,7.68},{53.43,7.1},{53.36,6.19},{53.37,5.66},{53.47,5.15},{53.64,4.64},{54.03,3.25}}}}}
G.patrolRoutes[15481]={[16]={{{52.98,81.73},{53.91,82.99},{55.51,84.0},{56.2,85.83},{56.33,86.8},{55.8,88.4},{54.98,90.12},{55.8,88.4},{56.6,86.78},{56.95,86.8},{57.71,88.13},{58.6,88.89},{57.71,88.14},{56.81,86.66},{57.3,85.51},{58.3,84.51},{58.41,83.98},{59.59,81.29},{59.94,80.79},{59.99,79.93},{59.94,79.14},{59.46,78.08},{58.82,77.29},{57.96,76.68},{57.05,78.15},{56.51,79.34},{55.69,79.6},{54.82,79.97},{54.38,79.79},{54.16,79.53},{53.26,80.39}}}}
function G:HelpMapTargets(entry,spoiler)
 local era=entry.stage<=6 and "Classic" or "Wotlk"
 local targets,seen={},{}
 local function add(key)
  for _,pt in ipairs(G.mapNPCs[key] or {}) do
   local id=pt.name..pt.zone..pt.x..":"..pt.y
   if not seen[id] then seen[id]=true;pt.npc=tonumber(key:match(":(%d+)$"));targets[#targets+1]=pt end
  end
 end
 local text=entry.title.." "..table.concat(entry.steps or {}," ")
 if spoiler then text=text.." "..(entry.spoiler or "") end
 for _,ref in ipairs(self.referenceCatalog) do
  if ref[4]=="npc" and text:find(ref[1],1,true) then add(era..":"..ref[5]) end
 end
 for _,ref in ipairs(self:HelpReferences(entry,spoiler)) do
  for _,pt in ipairs(ref.targets or {}) do
   local id=pt.name..pt.zone..pt.x..":"..pt.y
   if not seen[id] then seen[id]=true;targets[#targets+1]=pt end
  end
  local npc=ref[2]:match("npc=(%d+)")
  if npc then add(era..":"..npc) end
  local quest=ref[2]:match("quest=(%d+)")
  if quest then for _,key in ipairs(self.mapQuests[era..":"..quest] or {}) do add(key) end end
 end
 table.sort(targets,function(a,b) return a.name..a.zone<a.name..b.zone end)
 return targets
end
function G:DrawHelpPatrol(pt)
 if not pt.patrol or not self.patrolRoutes[pt.npc] then return false end
 if not QuestieLoader or not QuestieLoader.ImportModule then return false end
 local map=QuestieLoader:ImportModule("QuestieMap")
 if not map or not map.DrawManualIcon or not map.DrawWaypoints then return false end
 map:UnloadManualFrames(pt.npc,"SoloProgressGuide")
 for zone,path in pairs(self.patrolRoutes[pt.npc]) do
 local data={id=pt.npc,Name=pt.name,Type="manual",spawnType="monster",IsObjectiveNote=false,
  Icon="Interface\\WorldMap\\WorldMapPartyIcon",IconScale=0.7,GetIconScale=function() return 0.7 end,
  ManualTooltipData={Title=pt.name.." - маршрут патруля",Body={{"Solo Progress Guide","Место на маршруте, не текущее положение"}}}}
  local first=path[1][1]
  local icon=map:DrawManualIcon(data,zone,first[1],first[2],"SoloProgressGuide")
  if icon then
   map:DrawWaypoints(icon,path,zone,{0.1,0.9,1,1})
   for _,frame in ipairs(data.lineFrames or {}) do
    if frame.line then frame.line:SetThickness(3) end
    if frame.lineBorder then
     frame.lineBorder:SetThickness(5)
     frame.lineBorder:SetColorTexture(0,0,0,0.9)
    end
   end
  end
 end
 return true
end
function G:ShowMapTarget(pt,silent)
 if not pt or not GetMapZones or not WorldMapFrame or not SetMapZoom then
  if not silent then self:Print("Карта недоступна; координаты места указаны в карточке.") end
  return false
 end
 for continent=1,4 do
  for zone,name in ipairs({GetMapZones(continent)}) do
   if name==pt.zone or name==pt.zoneEN then
    if not WorldMapFrame:IsShown() then ShowUIPanel(WorldMapFrame) end
    SetMapZoom(continent,zone)
    if not silent then self:Print("Карта: "..pt.name.." — "..pt.zone..string.format(" %.1f, %.1f.",pt.x,pt.y)) end
    return true
   end
  end
 end
 if not silent then self:Print("Карта зоны не найдена: "..pt.zone) end
 return false
end
function G:PinHelpTarget(pt)
 -- Direct quest targets and overview entries use the same patrol metadata.
 local patrolNPC=pt.npc or (pt.kind=="npc" and pt.entityID)
 if patrolNPC and self.patrolRoutes[patrolNPC] then
  for _,era in ipairs({"Classic","Wotlk"}) do
   for _,known in ipairs(self.mapNPCs[era..":"..patrolNPC] or {}) do
    if known.zone==pt.zone or known.zoneEN==pt.zoneEN then
     pt={name=known.name,zone=known.zone,zoneEN=known.zoneEN,x=known.x,y=known.y,npc=patrolNPC,patrol=true}
     break
    end
   end
  end
 end
 self:ShowMapTarget(pt,true)
 local ok,route=pcall(self.DrawHelpPatrol,self,pt)
 if pt.patrol then
  if ok and route then self:Print("Маршрут патруля показан линиями Questie на карте.");return true end
  self:Print("Для линий патруля включите Questie; одиночная метка будет только ориентиром на маршруте, а не текущим положением персонажа.")
 end
 if not TomTom or not TomTom.AddZWaypoint then
  self:Print(pt.name..": "..pt.zone..string.format(" %.1f, %.1f. Для метки и стрелки включите TomTom.",pt.x,pt.y));return false
 end
 for continent=1,4 do
  for zone,name in ipairs({GetMapZones(continent)}) do
   if name==pt.zone or name==pt.zoneEN then
    local title=pt.name..(pt.patrol and " (место поиска)" or "")
    local pin=TomTom:AddZWaypoint(continent,zone,pt.x,pt.y,title,false,true,true,nil,true,true)
    if not pin then self:Print("Не удалось поставить метку: "..title);return false end
    if self.helpPin and self.helpPin~=pin and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(self.helpPin) end
    self.helpPin=pin
    self:Print("Метка: "..title.." - "..pt.zone..string.format(" %.1f, %.1f.",pt.x,pt.y))
    return true
   end
  end
 end
 self:Print("Карта зоны не найдена: "..pt.zone);return false
end

function G:ClearHelpMap()
 if self.helpPin and TomTom and TomTom.RemoveWaypoint then TomTom:RemoveWaypoint(self.helpPin) end
 self.helpPin=nil
 if QuestieLoader and QuestieLoader.ImportModule then
  local map=QuestieLoader:ImportModule("QuestieMap")
  if map and map.UnloadManualFrames then for npc in pairs(self.patrolRoutes) do map:UnloadManualFrames(npc,"SoloProgressGuide") end end
 end
 self:Print("Метки и маршрут путеводителя сняты.")
end
