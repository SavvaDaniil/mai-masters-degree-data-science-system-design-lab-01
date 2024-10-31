workspace {
    name "outlook.live.com"
    description "Электронная почта"

    !docs documentation

    # включаем режим с иерархической системой идентификаторов
    !identifiers hierarchical

    model {
        users = person "Users"
        outlook_mail_system = softwareSystem "Outlook Mail System" {
            description "Почтовая система"
            
            single_page_application = container "Single Page Application" {
                technology "Typescript and Angular"
                description "Front-end системы в браузере предоставляет пользователю интерфейс для взаимодействия с почтовой системой"
            }
            mobile_application = container "Mobile Application" {
                technology "Java for Android and Swift for IOS"
                description "Мобильные приложения для смартфонов"
            }
            desktop_application = container "Desktop Application" {
                technology "C++"
                description "Дэсктопное приложение преимущественно для Windows, идет в комплекте пакета Microsoft Office"
            }

            api_application = container "Api Application" "Выполняет бизнес-логику, вызываемую с помощью API методам [JSON/HTTPS]" {
                technology "Java Spring"

                api_user_controller = component "ApiUserController" {
                    technology "Spring Rest Controller"
                    description "Api методы для пользователей, авторизация, регистрация, восстановление пароля"
                }
                api_email_controller = component "ApiEmailController" {
                    technology "Spring Rest Controller"
                    description "Api методы для создания, редактирования, отправки писем"
                }
                api_email_folder_controller = component "ApiEmailToFolderController" {
                    technology "Spring Rest Controller"
                    description "Api мотеды для папок с писем и подключение к этим папкам самих писем"
                }

                user_middleware = component "UserMiddleware" {
                    description "Аутентификация, авторизация пользователей. Валидация и генерация паролей пользователей."
                }
                api_user_controller -> user_middleware "Аутентификация и авторизация"
                api_email_controller -> user_middleware "Аутентификация и авторизация"
                api_email_folder_controller -> user_middleware "Аутентификация и авторизация"


                user_facade = component "UserFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для пользователей"
                }
                user_repository = component "UserRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание нового пользователя. Поиск пользователя по логину, по маске имя и фамилия."
                }

                api_user_controller -> user_facade "Uses"
                user_facade -> user_repository "Uses"

                email_facade = component "EmailFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для взаимодействия пользователя с письмами"
                }
                email_repository = component "EmailRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание нового почтового письма. Получение письма по коду. Получение всех писем в папке (INNER JOIN)"
                }
                api_email_controller -> email_facade "Uses"
                email_facade -> email_repository "Uses"

                email_folder_facade = component "EmailFolderFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для взаимодействия пользователя с папками писем"
                }
                email_folder_repository = component "EmailFolderRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание новой почтовой папки. Получение перечня всех папок."
                }
                connection_email_to_email_folder_repository = component "ConnectionEmailToEmailFolderRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Осуществляет ManyToMany зависимость для писем и папок с письмами. Позволяет подключать/отключать письма к почтовым папкам."
                }
                api_email_folder_controller -> email_folder_facade "Uses"
                email_folder_facade -> email_folder_repository "Uses"
                email_folder_facade -> connection_email_to_email_folder_repository "Uses"
                email_facade -> connection_email_to_email_folder_repository "Подключить/отключить письмо от папки"

            }
            database = container "Database" "База данных системы, хранит информацию о пользователях, письмах и папках с письмами" {
                technology "PostegreSQL"
            }

            single_page_application -> api_application "Вызов методов по api [JSON, HTTPS]"
            api_application -> database "Сохранение и получение информации"

            
            single_page_application -> api_application.api_user_controller "Вызов api методов"
            single_page_application -> api_application.api_email_controller "Вызов api методов"
            single_page_application -> api_application.api_email_folder_controller "Вызов api методов"

            mobile_application -> api_application.api_user_controller "Вызов api методов"
            mobile_application -> api_application.api_email_controller "Вызов api методов"
            mobile_application -> api_application.api_email_folder_controller "Вызов api методов"

            desktop_application -> api_application.api_user_controller "Вызов api методов"
            desktop_application -> api_application.api_email_controller "Вызов api методов"
            desktop_application -> api_application.api_email_folder_controller "Вызов api методов"

            api_application.user_repository -> database "CRUD операции [SQL]"
            api_application.email_repository -> database "CRUD операции [SQL]"
            api_application.email_folder_repository -> database "CRUD операции [SQL]"
            api_application.connection_email_to_email_folder_repository -> database "CRUD операции [SQL]"
        }
        mail_server = softwareSystem "E-mail server" "Отдельный сервер, отвечающий за отправку писем"

        users -> outlook_mail_system "Uses"
        outlook_mail_system -> mail_server "Отправки электронных писем"
        mail_server -> users "Отправка электронных писем для"
        
        users -> outlook_mail_system.single_page_application "Взаимодействие через веб-браузер"
        users -> outlook_mail_system.mobile_application "Взаимодействие через смартфон"
        users -> outlook_mail_system.desktop_application "Взаимодействие через установленное дэкстопное приложение"
        outlook_mail_system.api_application -> mail_server "Отправки электронных писем"

        outlook_mail_system.api_application.email_facade -> mail_server "Отправки электронных писем"

    }

    views {

        themes default

        systemContext outlook_mail_system {
            include *
            autoLayout
        }

        container outlook_mail_system {
            include *
            autoLayout lr
        }

        component outlook_mail_system.api_application {
            include *
            autoLayout lr
        }

        dynamic outlook_mail_system "api_user_add" "Создание нового пользователя" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Создание нового пользователя"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /api/user"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO user VALUES(...)"
        }

        dynamic outlook_mail_system "api_user_search_username" "Поиск пользователя по логину" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Поиск пользователя по логину"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "POST /api/user/search/username"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM user WHERE username = ?"
        }

        dynamic outlook_mail_system "api_user_search_with_firstname_lastname" "Поиск пользователя по маске имя и фамилия" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Поиск пользователя по маске имя и фамилия"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "POST /api/user/search"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM user WHERE firstname = '%?%' AND secondname = '%?%'"
        }

        dynamic outlook_mail_system "api_email_folder_add" "Создание новой почтовой папки" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Создание новой почтовой папки"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /api/email_folder"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO mail_folder VALUES(...)"
        }

        dynamic outlook_mail_system "api_email_folder_list_all" "Получение перечня всех папок" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение перечня всех папок"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /api/email_folder/list_all"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM  mail_folder"
        }

        dynamic outlook_mail_system "api_email_folder_add_email" "Создание нового письма в папке" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Создание нового письма в папке"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /api/email_folder/email"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO mail VALUES(...);INSERT INTO connection_mail_to_mail_folder VALUES(...)"
        }

        dynamic outlook_mail_system "api_email_folder_email_list" "Получение всех писем в папке" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение всех писем в папке"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /api/email_folder/{email_folder_id}/email_list"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM mail INNER JOIN connection_mail_to_mail_folder ON connection_mail_to_mail_folder.mail_id = mail.id AND ..."
        }

        dynamic outlook_mail_system "api_mail_get_by_code" "Получение письма по коду" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение письма по коду"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /api/email/code/{code}"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM mail WHERE code = ?"
        }
        
        styles {
            
        }

    }
}