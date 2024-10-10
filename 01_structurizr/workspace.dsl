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

                user_controller = component "UserController" {
                    technology "Spring Rest Controller"
                    description "Api методы для пользователей, авторизация, регистрация, восстановление пароля"
                }
                mail_controller = component "MailController" {
                    technology "Spring Rest Controller"
                    description "Api методы для создания, редактирования, отправки писем"
                }
                mail_folder_controller = component "MailToFolderController" {
                    technology "Spring Rest Controller"
                    description "Api мотеды для папок с писем и подключение к этим папкам самих писем"
                }

                user_security_util = component "UserSecurityUtil" {
                    description "Аутентификация, авторизация пользователей. Валидация и генерация паролей пользователей."
                }
                user_controller -> user_security_util "Аутентификация и авторизация"
                mail_controller -> user_security_util "Аутентификация и авторизация"
                mail_folder_controller -> user_security_util "Аутентификация и авторизация"


                user_facade = component "UserFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для пользователей"
                }
                user_repository = component "UserRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание нового пользователя. Поиск пользователя по логину, по маске имя и фамилия."
                }

                user_controller -> user_facade "Uses"
                user_facade -> user_repository "Uses"

                mail_facade = component "MailFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для взаимодействия пользователя с письмами"
                }
                mail_repository = component "MailRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание нового почтового письма. Получение письма по коду. Получение всех писем в папке (INNER JOIN)"
                }
                mail_controller -> mail_facade "Uses"
                mail_facade -> mail_repository "Uses"

                mail_folder_facade = component "MailFolderFacade" {
                    technology "Spring Bean"
                    description "Бизнес-логика для взаимодействия пользователя с папками писем"
                }
                mail_folder_repository = component "MailFolderRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Создание новой почтовой папки. Получение перечня всех папок."
                }
                connection_mail_to_mail_folder_repository = component "ConnectionMailToMailFolderRepository" {
                    technology "Spring Bean"
                    description "ORM JPA. Осуществляет ManyToMany зависимость для писем и папок с письмами. Позволяет подключать/отключать письма к почтовым папкам."
                }
                mail_folder_controller -> mail_folder_facade "Uses"
                mail_folder_facade -> mail_folder_repository "Uses"
                mail_folder_facade -> connection_mail_to_mail_folder_repository "Uses"
                mail_facade -> connection_mail_to_mail_folder_repository "Подключить/отключить письмо от папки"

            }
            database = container "Database" "База данных системы, хранит информацию о пользователях, письмах и папках с письмами" {
                technology "PostegreSQL"
            }

            single_page_application -> api_application "Вызов методов по api [JSON, HTTPS]"
            api_application -> database "Сохранение и получение информации"

            
            single_page_application -> api_application.user_controller "Вызов api методов"
            single_page_application -> api_application.mail_controller "Вызов api методов"
            single_page_application -> api_application.mail_folder_controller "Вызов api методов"

            mobile_application -> api_application.user_controller "Вызов api методов"
            mobile_application -> api_application.mail_controller "Вызов api методов"
            mobile_application -> api_application.mail_folder_controller "Вызов api методов"

            desktop_application -> api_application.user_controller "Вызов api методов"
            desktop_application -> api_application.mail_controller "Вызов api методов"
            desktop_application -> api_application.mail_folder_controller "Вызов api методов"

            api_application.user_repository -> database "CRUD операции [SQL]"
            api_application.mail_repository -> database "CRUD операции [SQL]"
            api_application.mail_folder_repository -> database "CRUD операции [SQL]"
            api_application.connection_mail_to_mail_folder_repository -> database "CRUD операции [SQL]"
        }
        mail_server = softwareSystem "E-mail server" "Отдельный сервер, отвечающий за отправку писем"

        users -> outlook_mail_system "Uses"
        outlook_mail_system -> mail_server "Отправки электронных писем"
        mail_server -> users "Отправка электронных писем для"
        
        users -> outlook_mail_system.single_page_application "Взаимодействие через веб-браузер"
        users -> outlook_mail_system.mobile_application "Взаимодействие через смартфон"
        users -> outlook_mail_system.desktop_application "Взаимодействие через установленное дэкстопное приложение"
        outlook_mail_system.api_application -> mail_server "Отправки электронных писем"

        outlook_mail_system.api_application.mail_facade -> mail_server "Отправки электронных писем"

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
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /user"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO user VALUES(...)"
        }

        dynamic outlook_mail_system "api_user_search" "Поиск пользователя по логину" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Поиск пользователя по логину"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "POST /user/search"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM user WHERE username = ?"
        }

        dynamic outlook_mail_system "api_user_search_with_firstname_lastname" "Поиск пользователя по маске имя и фамилия" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Поиск пользователя по маске имя и фамилия"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "POST /user/search"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM user WHERE firstname = '%?%' AND secondname = '%?%'"
        }

        dynamic outlook_mail_system "api_mail_folder_add" "Создание новой почтовой папки" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Создание новой почтовой папки"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /mail_folder"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO mail_folder VALUES(...)"
        }

        dynamic outlook_mail_system "api_mail_folder_list_all" "Получение перечня всех папок" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение перечня всех папок"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /mail_folder/all"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM  mail_folder"
        }

        dynamic outlook_mail_system "api_mail" "Создание нового письма в папке" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Создание нового письма в папке"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "PUT /mail"
            outlook_mail_system.api_application -> outlook_mail_system.database "INSERT INTO mail VALUES(...);INSERT INTO connection_mail_to_mail_folder VALUES(...)"
        }

        dynamic outlook_mail_system "api_mail_by_mail_folder" "Получение всех писем в папке" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение всех писем в папке"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /mail/mail_folder/{mail_folder_id}"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM mail INNER JOIN connection_mail_to_mail_folder ON connection_mail_to_mail_folder.mail_id = mail.id AND ..."
        }

        dynamic outlook_mail_system "api_mail_get_by_code" "Получение письма по коду" {
            autoLayout lr

            users -> outlook_mail_system.single_page_application "Получение письма по коду"
            outlook_mail_system.single_page_application -> outlook_mail_system.api_application "GET /mail/{code}"
            outlook_mail_system.api_application -> outlook_mail_system.database "SELECT * FROM mail WHERE code = ?"
        }
        
        styles {
            
        }

    }
}