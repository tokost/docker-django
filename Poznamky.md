>###Pripojenie aplikácie Django k databáze PostgreSQL

Chybové hlásenie naznačuje, že vaša aplikácia Django sa nedokáže pripojiť k databáze PostgreSQL. Je potrebné zvážiť niekoľko problémov a možných opráv:

## Problémy:
1. Pomenovanie služby : V docker-compose.yml súbore je databázová služba pomenovaná db, ale DB_HOSTpremenná prostredia pre webovú službu je nastavená na docker-django-db-1.
2. Načítanie premenných prostredia : Uistite sa, že .envsúbor je správne naformátovaný a umiestnený v koreňovom adresári vášho projektu.
V3. erzia Docker Compose : Upozornenie na zastaranú verziu môže naznačovať problémy s kompatibilitou. Pomôcť môže aktualizácia syntaxe Docker Compose.

Aktualizácia docker-compose.yml:
Uistite sa, že sa názvy služieb zhodujú a že premenné prostredia sú správne definované.

**Súbor docker-compose.yml** 
~~~
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8001
    ports:
      - "8001:8001"
    volumes:
      - .:/code
    networks:
      - backend
    environment:
      - DEBUG=True
      - DB_NAME=postgres
      - DB_USER=postgres
      - DB_PASSWORD=postgres
      - DB_HOST=db  # Changed to match the service name
    depends_on:
      - db

  db:
    image: postgres
    environment:
      POSTGRES_DB: postgres
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: postgres
    ports:
      - "5432:5432"
    networks:
      - backend

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: tokos@comto.sk
      PGADMIN_DEFAULT_PASSWORD: admin
    depends_on:
      - db
    ports:
      - "8080:80"
    networks:
      - backend

networks:
  backend:
    driver: bridge

~~~
**Súbor .env**
Uistite sa, že premenné prostredia sú správne definované bez medzier okolo znaku =.

~~~
POSTGRES_PASSWORD=postgres
POSTGRES_USER=postgres
DJANGO_SECRET_KEY=django-insecure-35@5y_@t@n@ybr3_-g=emn2pjhjwl88l37(k(5@1aa)87-xl68
DJANGO_SU_NAME=admin
DJANGO_SU_EMAIL=info@comto.sk
DJANGO_SU_PASSWORD=admin
~~~

**Súbor settings.py**
Uistite sa, že nastavenia Django správne získavajú premenné prostredia.

~~~
import os
...
POSTGRES_PASSWORD = os.environ.get('POSTGRES_PASSWORD')
POSTGRES_USER = os.environ.get('POSTGRES_USER')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.environ.get('DB_NAME', 'postgres'),
        'USER': os.environ.get('DB_USER', 'postgres'),
        'PASSWORD': os.environ.get('DB_PASSWORD', 'postgres'),
        'HOST': os.environ.get('DB_HOST', 'db'),
        'PORT': '5432',
    }
}
...
~~~

## Kroky na spustenie:

1. Zničte existujúce kontajnery : Uistite sa, že nie sú spustené žiadne konfliktné kontajnery.

~~~
docker-compose down
~~~

2. Zostavte a spustite kontajnery : Zostavte a spustite kontajnery s aktualizovanou konfiguráciou.

~~~
docker-compose up --build -d
~~~
3. Skontrolujte stav kontajnera : Uistite sa, že všetky kontajnery sú v prevádzke.

~~~
docker-compose ps
~~~

4. Spustite migráciu databázy : Pred vytvorením superužívateľa sa uistite, že vaša databáza je migrovaná. Stačí na to použiť meno **web**
~~~
$ docker-compose exec web python manage.py migrate
~~~

5. Create Superuser : Vytvorte superužívateľa ak po migrácii nebol zapísaný z predchádzajúca. Názov kontajnera stačí pužiť **web**
~~~
$ docker-compose exec web python manage.py createsuperuser
~~~
Podľa týchto krokov by sa vaša aplikácia Django mala vedieť pripojiť k databáze PostgreSQL a mali by ste byť schopní vytvoriť superužívateľa.


>###Utajenie citlivýúdajov do .env

Ak chcete v súbore skryť citlivé údaje do .env, môžete odkazovať na premenné prostredia v súboroch settings.py a docker-compose.yml. Môžete to urobiť takto:

1. Presunúť citlivé údaje do .env súboru : Vytvorte .env súbor v koreňovom adresári svojho projektu, ak neexistuje, a presuňte tam všetky citlivé informácie.

~~~
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_USER=your_postgres_user
DB_NAME=your_db_name
DB_HOST=your_container_db_name or iba db

DJANGO_SECRET_KEY=your_django_secret_key
DJANGO_SU_NAME=admin
DJANGO_SU_EMAIL=your_email
DJANGO_SU_PASSWORD=your_su_password
~~~

2. Aktualizácia docker-compose.yml na používanie premenných prostredia : Odkazujte na premenné prostredia v docker-compose.yml súbore.

~~~
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8001
    ports:
      - "8001:8001"
    volumes:
      - .:/code
    networks:
      - backend
    env_file:
      - .env
    depends_on:
      - db

  db:
    image: postgres
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    networks:
      - backend

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: tokos@comto.sk
      PGADMIN_DEFAULT_PASSWORD: admin
    depends_on:
      - db
    ports:
      - "8080:80"
    networks:
      - backend

networks:
  backend:
    driver: bridge
~~~

3. Aktualizácia settings.py na používanie premenných prostredia : Importujte dotenvbalík na načítanie premenných prostredia zo .env súboru a odkazujte na ne vo svojom súbore settings.py.

Najprv nainštalujte python-dotenv balík, ak ste tak ešte neurobili:
~~~
pip install python-dotenv
~~~

Potom aktualizujte svoj settings.py súbor:

~~~
import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

# Database
# https://docs.djangoproject.com/en/3.2/ref/settings/#databases

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'postgres'),
        'USER': os.getenv('DB_USER', 'postgres'),
        'PASSWORD': os.getenv('DB_PASSWORD', 'postgres'),
        'HOST': os.getenv('DB_HOST', 'db'),
        'PORT': '5432',
    }
}

# Superuser configuration
DJANGO_SU_NAME = os.getenv('DJANGO_SU_NAME', 'admin')
DJANGO_SU_EMAIL = os.getenv('DJANGO_SU_EMAIL', 'info@comto.sk')
DJANGO_SU_PASSWORD = os.getenv('DJANGO_SU_PASSWORD', 'admin')
~~~

## Záverečné kroky:

1. Znova zostaviť kontajnery Docker : Prestavte kontajnery Docker, aby ste použili zmeny.
~~~
docker-compose down
docker-compose up --build -d
~~~

2. Spustite migrácie a vytvorte superužívateľa : Uistite sa, že databáza je migrovaná a vytvorte superužívateľa.
~~~
docker-compose exec web python manage.py migrate
docker-compose exec web python manage.py createsuperuser
~~~

Dodržaním týchto krokov zaistíte, že citlivé údaje sú bezpečne uložené v súbore .env a správne sa na ne odkazuje vo vašich konfiguračných súboroch. Tento prístup udrží vaše citlivé údaje skryté a vašu konfiguráciu čistú.

>##Nevadí, že v súbore settings.py sú stále viditeľné citlivé údaje?

Áno, na zvýšenie bezpečnosti je dôležité uchovávať citlivé údaje, ako sú poverenia databázy a tajné kľúče, mimo vášho súboru. Môžete to dosiahnuť pomocou premenných prostredia na správu citlivých informácií. Tu je návod, ako zabezpečiť, aby sa s citlivými údajmi zaobchádzalo správne:

##Používanie premenných prostredia

1. Vytvoriť .env súbor : Tento súbor by mal uchovávať všetky vaše citlivé informácie a nemal by byť viazaný na váš systém správy verzií git. T.j. treba ho vložiť do .gitignore

**Súbor .env**
~~~
POSTGRES_PASSWORD=postgres
POSTGRES_USER=postgres
POSTGRES_DB=postgres
DJANGO_SECRET_KEY=django-insecure-35@5y_@t@n@ybr3_-g=emn2pjhjwl88l37(k(5@1aa)87-xl68
DJANGO_SU_NAME=admin
DJANGO_SU_EMAIL=info@comto.sk
DJANGO_SU_PASSWORD=admin
~~~

2. Upraviť súbor docker-compose.yml : Uistite sa, že vaše služby načítavajú premenné prostredia zo súboru .env .

~~~
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8001
    ports:
      - "8001:8001"
    volumes:
      - .:/code
    networks:
      - backend
    env_file:
      - .env  # Use .env file
    depends_on:
      - db

  db:
    image: postgres
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    networks:
      - backend

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: tokos@comto.sk
      PGADMIN_DEFAULT_PASSWORD: admin
    depends_on:
      - db
    ports:
      - "8080:80"
    networks:
      - backend

networks:
  backend:
    driver: bridge
~~~

3. Update súbor settings.py : Na čítanie týchto premenných použite **os.environ**.

~~~
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# SECURITY WARNING: keep the secret key used in production secret!
SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = os.getenv('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = []

# Application definition

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XContentOptionsMiddleware',
]

ROOT_URLCONF = 'myproject.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'myproject.wsgi.application'

# Database
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB'),
        'USER': os.getenv('POSTGRES_USER'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD'),
        'HOST': os.getenv('DB_HOST', 'db'),
        'PORT': '5432',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

# Internationalization
LANGUAGE_CODE = 'en-us'
TIME_ZONE = 'UTC'
USE_I18N = True
USE_L10N = True
USE_TZ = True

# Static files (CSS, JavaScript, Images)
STATIC_URL = '/static/'
~~~

## Zabezpečte bezpečnosť:

1. Pridať .env do.gitignore : Ak chcete zabrániť presunu súboru .env do vášho systému správy verzií, pridajte ho do .gitignore.

~~~
echo '.env' >> .gitignore
~~~

2. Používanie tajných kľúčov Docker alebo externých trezorov : V produkčnom prostredí zvážte použitie tajných kľúčov Docker, HashiCorp Vault, AWS Secrets Manager alebo inej bezpečnej metódy na správu citlivých informácií.

>###Dodržaním týchto krokov zaistíte, že citlivé údaje nebudú pevne zakódované vo vašich zdrojových súboroch a budú spravované bezpečne pomocou premenných prostredia.

>###Inštalovať python-dotenv : Doporučujeme pridat python-dotenv balík do svojho requirements.txt súboru.

~~~
django
psycopg2-binary
python-dotenv
~~~




>##V najnovších verziách Docker Compose už kľúč pre verziu v s=ubore docker-compose nie je potrebný .
~~~
napr. version: "3.8"
~~~
Varovné hlásenie version znamená že to je zastarané, čo znamená, t.j. váš docker-compose.yml súbor používa syntax zastaranej verzie. version  Môžete ho odstrániť alebo aktualizovať na najnovší formát.

1. Aktualizácia docker-compose.yml
Odstráňte alebo aktualizujte kľúč verzie vo svojom docker-compose.ymlsúbore. Ak používate Docker Compose V2 alebo novší, môžete versionkľúč bezpečne úplne odstrániť. Tu je príklad vyriešenia tohoto problému:
~~~
services:
  db:
    image: postgres:latest
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword

    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - db

volumes:
  postgres_data:
~~~

>##Nastavenie Django ALLOWED_HOSTS

Chyba CommandError: You must set settings.ALLOWED_HOSTS if DEBUG is False znamená, že nastavenie ALLOWED_HOSTS v Django settings.py nie je správne nakonfigurované. Toto nastavenie je potrebné na určenie, ktoré názvy hostiteľov/domén môže stránka Django poskytovať, keď DEBUG je nastavené na False.

Vyriešenie tohoto problému:

2. Nakonfigurujte ALLOWED_HOSTSv Django
Musíte nastaviť ALLOWED_HOSTSv nastaveniach Django. Ak používate premenné prostredia, môžete ich nastaviť dynamicky na základe prostredia. Tu je príklad úpravy vášho settings.pysúboru:
~~~
import os

DEBUG = os.getenv('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', '').split(',')

# Example for development purposes:
# ALLOWED_HOSTS = ['localhost', '127.0.0.1', '[::1]']

# Add other settings here...
~~~
Potom vo svojom docker-compose.yml súbore nastavte ALLOWED_HOSTS premennú prostredia:
~~~
services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - ALLOWED_HOSTS=localhost,127.0.0.1
      - DEBUG=False
~~~

Zhrnutie
Aktualizujte docker-compose.yml na odstránenie kľúča version, ak používate Docker Compose V2 alebo novší.
Nakonfigurujte ALLOWED_HOSTS vo svojom Django settings.py a nastavte zodpovedajúcu premennú prostredia v docker-compose.yml.


>##Ak protokoly chýb naznačujú, že chýba dotenv modul, čo spôsobuje vypnutie webového kontajnera Django a ak chcete vyriešiť tento problém, musíte sa uistiť, že python-dotenv je nainštalovaný v kontajneri Docker vášho projektu Django.

Tu je podrobný návod na vyriešenie problému:

1. Aktualizácia requirements.txt: 
Uistite sa, že python-dotenv je to uvedené vo vašom  requirements.txt. Ak tam nie je, pridajte ho:
~~~
python-dotenv
~~~
alebo
~~~
django>=3.0,<4.0
djangorestframework
psycopg2-binary
python-dotenv
~~~

2. Overte Dockerfile: 
Uistite sa, že váš Dockerfilenainštaloval závislosti z requirements.txt. Mal by mať riadok ako:
~~~
...
RUN pip install -r requirements.txt
...
~~~

3. Znova vytvorte obraz Docker: 
Po aktualizácii requirements.txt znova vytvorte svoj obraz Docker, aby ste nainštalovali nové závislosti. Spustite nasledujúci príkaz:
~~~
docker-compose build
~~~

4. Reštartujte kontajnery: 
Po opätovnom zostavení obrázka spustite kontajnery znova:
~~~
docker-compose up
~~~

## Overenie opravy:

Po vykonaní vyššie uvedených krokov docker-django-web-1 by sa mal váš kontajner spustiť bez vypnutia a mali by ste vidieť protokoly označujúce, že server Django je spustený.

Ak problém pretrváva, možno budete chcieť manuálne skontrolovať, či python-dotenv je v kontajneri nainštalovaný:

1. Prístup k webovému kontajneru: 
Spustite kontajnery v oddelenom režime:
~~~
docker-compose up -d
~~~

2. Získajte ID kontajnera pre webovú službu:
~~~
docker ps
~~~

3. Prístup k plášťu kontajnera:
~~~
docker exec -it <container_id> /bin/bash
~~~

4. Skontrolujte, či python-dotenv je nainštalovaný:
~~~
pip list | grep python-dotenv
~~~

Ak python-dotenv je uvedené, malo by to vyriešiť chybu importu. Ak nie, môže nastať problém so spôsobom inštalácie závislostí a mali by ste sa uistiť, že requirements.txtje to správne špecifikované vo vašom súbore Dockerfile.

>##Zachovanie údajov zaregistrovaného servera v dockerovom pgAdmin

Tu sú kroky, ako to dosiahnuť:

1. Vytvorte volumes (zväzok) pre údaje pgAdmin vo svojom súbore docker-compose.yml.

2. Pripojte zväzok do príslušného adresára v kontajneri pgAdmin.

Aktualizujte svoj tak docker-compose.yml, aby obsahoval zväzok údajov pgAdmin:
~~~
services:
  db:
    image: postgres:latest
    environment:
      POSTGRES_DB: mydatabase
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    volumes:
      - postgres_data:/var/lib/postgresql/data

  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    volumes:
      - .:/code
    ports:
      - "8000:8000"
    depends_on:
      - db

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "5050:80"
    depends_on:
      - db
    volumes:
      - pgadmin_data:/var/lib/pgadmin

volumes:
  postgres_data:
  pgadmin_data:
~~~

## Vysvetlenie
* Zvezok pre údaje Postgres : *postgres_data* je už nastavený na uchovávanie údajov PostgreSQL.

* Zvezok pre údaje pgAdmin : *pgadmin_data* je pridaný k zachovaniu konfiguračných údajov pgAdmin.

## Kroky na uplatnenie zmien

1. Zastavte a odstráňte existujúce kontajnery:
~~~
$ docker-compose down
~~~
2. Vytvorte kontajnery s aktualizovanou konfiguráciou :
~~~
$ docker-compose up -d
~~~
Toto nastavenie zaisťuje, že dáta pgAdmina *pgadmin_data*, ako sú registrované servery a iné konfigurácie, budú na zväzku zachované aj počas reštartov a opakovaní kontajnera.

##Overenie trvanlivosti údajov
1. Zaregistrujte nový server v pgAdmin .

2. Zastavte kontajnery :
~~~
$ docker-compose stop
~~~

3. Znova spustite kontajnery :
~~~
$ docker-compose start
~~~

4. Prejdite do pgAdmin a overte, či je zaregistrovaný server stále dostupný.

5. Ak urobím migraciu ktorá mi zobrazí v pgAdmin tabuľky, tak sa mi v takomto pgAdmin tieto tabuľky tiež zachovajú a nemusím stale používať tento príkaz:
~~~
$ docker-compose exec web python manage.py migrate
~~~

>##Ak prestane fungovať raketa a prehliadač hlási na adrese localhost:8001 **Not Found** The requested resource was not found on this server.

### Úplný príklad požadovaných súborov

Tu je úplný príklad súborov zahrnutých v tomto nastavení:

Obsah súboru myapp/views.py :
~~~
from django.http import HttpResponse

def home(request):
    return HttpResponse("Hello, world!")
~~~

Obsah súboru urls.py :
~~~
from django.contrib import admin
from django.urls import path
from myapp import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', views.home, name='home'),
]
~~~

Obsah súboru docker-compose.yml :
~~~
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8001
    ports:
      - "8001:8001"
    volumes:
      - .:/code
    networks:
      - backend
    env_file:
      - .env
    depends_on:
      - db
    environment:
      - ALLOWED_HOSTS=localhost,127.0.0.1
      - DEBUG=False

  db:
    image: postgres:latest
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    networks:
      - backend

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
    ports:
      - "8080:80"
    depends_on:
      - db
    volumes:
      - pgadmin_data:/var/lib/pgadmin
    networks:
      - backend

networks:
  backend:
    
 
driver: bridge

volumes:
  postgres_data:
  pgadmin_data:
~~~

Obsah súboru settings.py :
~~~
import os
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY')

DEBUG = os.getenv('DEBUG', 'False') == 'True'

ALLOWED_HOSTS = os.getenv('ALLOWED_HOSTS', 'localhost').split(',')

INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    
    
'django.contrib.staticfiles',
    'myapp',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    
  
'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

ROOT_URLCONF = 'mysite.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            
         
'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 
            ],
       
'mysite.wsgi.application'

DATABASES = {
    'default': {
        
        
'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('POSTGRES_DB'),
        'USER': os.getenv('POSTGRES_USER'),
        'PASSWORD': os.getenv('POSTGRES_PASSWORD'),
        'HOST': os.getenv('DB_HOST', 'db'),
        'PORT': '5432',
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
        
    }
}

AUTH_PASSWORD_VALIDATORS = [
    {
     
'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        
 
'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]

LANGUAGE_CODE = 
    },
]
'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_L10N = True

USE_TZ = 

US
True

STATIC_URL = '/static/'

DEFAULT_AUTO_FIELD = 

DEF
'django.db.models.BigAutoField'
~~~

>##Kontrola premenných prostredia pomocou prostredia Shell:
Môžete skontrolovať, či sa premenné prostredia načítavajú správne, spustením shellu Pythonu vo vašom virtuálnom prostredí a pokusom o vytlačenie premenných prostredia:
~~~
$ python manage.py shell
>>> import os
>>> print(os.environ.get('SECRET_KEY'))
Ak vypíše správne SECRET_KEY, potom sa premenné prostredia načítavajú správne.

>##Overenie inštalácie knižníc:
Uistite sa, že máte django-enviro na python-dotenv máte nainštalované vo svojom virtuálnom prostredí:
~~~
$ pip install django-environ python-dotenv
~~~
Podľa týchto krokov by ste mali byť schopní vyriešiť problém s chýbajúcimi alebo nesprávne nakonfigurovanými premennými prostredia vo vašom projekte Django.


>##Kontrola používateľa a hesla PostgreSQL

Overte, či používateľ „postgres“ (alebo používateľ, pod ktorého sa pokúšate pripojiť) existuje vo vašej databáze PostgreSQL a či je heslo správne. Môžete to urobiť manuálnym pripojením k databáze pomocou nástroja ako je terminál psql alebo grafického nástroja ako pgAdmin:
~~~
psql -h your_database_host -U your_postgres_user -d your_database_name
~~~
Napríklad
~~~
psql -h localhost -U postgres -d my_web_db
~~~
Zobrazí sa výzva na zadanie hesla. Ak sa môžete úspešne prihlásiť, prihlasovacie údaje sú správne.

>##Poškodené údaje relácie
Správa „Session data corrupted (Údaje relácie sú poškodené)“ označuje problém s údajmi relácie Django, ku ktorému môže dôjsť z rôznych dôvodov, ako je nesprávne nakonfigurovaný koniec relácie alebo poškodenie údajov relácie vo vašom úložisku (napr. databáza, súborový systém alebo vyrovnávacia pamäť). .

Tu je niekoľko krokov na riešenie a vyriešenie problému „Údaje relácie sú poškodené“:

1. Skontrolujte konfiguráciu backendu relácie
Uistite sa, že váš modul relácie je správne nakonfigurovaný v settings.py. Predvolený nástroj relácie používa databázu na ukladanie údajov relácie.
~~~
# Session settings
SESSION_ENGINE = 'django.contrib.sessions.backends.db'  # Use database-backed sessions
# SESSION_ENGINE = 'django.contrib.sessions.backends.cache'  # Use cache-backed sessions
# SESSION_ENGINE = 'django.contrib.sessions.backends.cached_db'  # Use combined database and cache-backed sessions
~~~

2. Vymažte existujúce relácie
Niekedy môžu byť údaje existujúcej relácie poškodené. Vymažte tabuľku relácií v databáze.
~~~
python manage.py clearsessions
~~~

3. Skontrolujte migrácie databázy
Uistite sa, že všetky migrácie boli aplikované správne, najmä ak ste nedávno zmenili mechanizmus relácie alebo vykonali zmeny v schéme databázy.
~~~
python manage.py makemigrations
python manage.py migrate
~~~

4. Skontrolujte údaje relácie
Ak používate databázu pre relácie, skontrolujte údaje relácie priamo, aby ste skontrolovali akékoľvek zjavné poškodenie.

Použitie Django Shell:
~~~
python manage.py dbshell
~~~

V prostredí databázy môžete spustiť:
~~~
SELECT * FROM django_session;
~~~

5. Kontrola integrity databázy
Uistite sa, že vaša databáza nemá žiadne problémy s integritou. Pre PostgreSQL môžete použiť REINDEXpríkaz:
~~~
psql -U your_db_user -d your_db_name -c "REINDEX TABLE django_session;"
~~~

6. Ďalšie podrobnosti nájdete v protokoloch
Skontrolujte svoje denníky Django, kde nájdete podrobnejšie chybové hlásenia, ktoré by vám mohli poskytnúť predstavu o tom, čo spôsobuje poškodenie relácie.

7. Prepnúť na iný backend relácie (voliteľné)
Ak problém pretrváva, zvážte prechod na iný backend relácie, ako je napríklad backend vyrovnávacej pamäte.

Príklad použitia relácií zálohovaných vyrovnávacou pamäťou:
~~~
SESSION_ENGINE = 'django.contrib.sessions.backends.cache'
SESSION_CACHE_ALIAS = 'default'
~~~

Uistite sa, že máte vo svojom settings.py:
~~~
CACHES = {
    'default': {
        'BACKEND': 'django.core.cache.backends.memcached.MemcachedCache',
        'LOCATION': '127.0.0.1:11211',
    }
}
~~~

8. Ladenie pomocou podrobného protokolovania
Povoľte podrobné zapisovanie relácií do denníka, aby ste získali viac informácií.
~~~
import logging

logger = logging.getLogger('django.session')
logger.setLevel(logging.DEBUG)
~~~

###Zhrnutie
Podľa týchto krokov by ste mali byť schopní identifikovať a vyriešiť problém, ktorý spôsobuje správy „Údaje relácie sú poškodené“. Začnite tým, že skontrolujete konfiguráciu vašej relácie, vymažete existujúce relácie a uistíte sa, že vaša databáza je v dobrom stave. V prípade potreby prepnite na iný backend relácie a povoľte podrobnejšie protokolovanie, aby ste získali lepší prehľad.


>##Príliš veľa identických záznamov v protokoloch dockera pgadmin4_container

Ak v protokoloch vidíte príliš veľa identických záznamov denníka pgadmin4_container, môžete vykonať nasledujúce kroky na spravovanie a zníženie výstupu denníka:

1. Identifikujte a vyriešte zdroj protokolov
Najprv identifikujte zdroj opakovaných záznamov denníka. Protokoly môžu indikovať problém s konfiguráciou alebo chybu aplikácie, ktorú je potrebné vyriešiť.

* Skontrolujte obsah správ denníka, aby ste pochopili, čo sa opakovane zaznamenáva.
* V správach denníka vyhľadajte vzory alebo chyby, ktoré by mohli naznačovať hlavnú príčinu problému.

2. Upravte úroveň protokolovania PgAdmin

PgAdmin môžete nakonfigurovať tak, aby znížil podrobnosť svojich protokolov nastavením vyššej úrovne protokolovania. Štandardne môžu byť protokoly PgAdmin nastavené na podrobnú úroveň (napr. DEBUG alebo INFO). Zmena úrovne protokolovania na WARNING alebo ERROR môže pomôcť znížiť počet záznamov protokolu.

    1. Vytvorte vlastný konfiguračný súbor *config_local.py* s požadovanou úrovňou protokolovania:
~~~
import logging

LOG_LEVEL = logging.ERROR
~~~

    2. Pripojte tento konfiguračný súbor do kontajnera PgAdmin pomocou vášho súboru docker-compose.yml:
~~~
version: '3.8'
services:
  pgadmin4:
    image: dpage/pgadmin4
    container_name: pgadmin4_container
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "80:80"
    volumes:
      - ./config_local.py:/pgadmin4/config_local.py
~~~

3. Obmedzte veľkosť denníka a povoľte rotáciu denníka

Nakonfigurujte Docker tak, aby obmedzil veľkosť protokolových súborov a povolil rotáciu protokolov, aby sa zabránilo neobmedzenému množeniu protokolových súborov.
~~~
version: '3.8'
services:
  pgadmin4:
    image: dpage/pgadmin4
    container_name: pgadmin4_container
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "80:80"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
~~~

4. Použite iný protokolový ovládač

Zvážte použitie iného ovládača protokolovania, ktorý lepšie vyhovuje vašim potrebám, napríklad *syslog* alebo *fluentd*. Tieto ovládače vám môžu pomôcť efektívnejšie spravovať a analyzovať protokoly.
~~~
version: '3.8'
services:
  pgadmin4:
    image: dpage/pgadmin4
    container_name: pgadmin4_container
    environment:
      PGADMIN_DEFAULT_EMAIL: admin@example.com
      PGADMIN_DEFAULT_PASSWORD: admin
    ports:
      - "80:80"
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://192.168.0.42:123"
~~~

5. Filtrovanie denníkov

Protokoly môžete filtrovať pomocou *grep* alebo iných nástrojov na správu protokolov, aby ste sa zamerali na konkrétne úrovne protokolov alebo správy.
~~~
docker logs pgadmin4_container 2>&1 | grep ERROR

6. Reštartujte kontajner

Niekedy môže reštartovanie kontajnera pomôcť vyriešiť prechodné problémy, ktoré môžu spôsobovať nadmerné zapisovanie do denníka.

~~~
docker-compose restart pgadmin4_container
~~~

7. Analyzujte aplikačný kód

Ak sú opakované položky protokolu spôsobené problémom aplikácie, ako je napríklad slučka alebo opakujúca sa chyba, analyzujte a aktualizujte kód aplikácie, aby ste vyriešili základný problém.

Dodržiavaním týchto krokov môžete efektívne spravovať a redukovať výstup protokolovania z *pgadmin4_container* a zabezpečiť, aby boli vaše protokoly zmysluplnejšie a ľahšie sa s nimi pracovalo.


>##Čo je pipfile a ako sa používa

Pipfile je súčasťou ekosystému balenia Pythonu a používa sa na správu závislostí projektu spôsobom, ktorý je pre používateľa príjemnejší a výkonnejší ako tradičný súbor requirements.txt. Pipfile je navrhnutý tak, aby spolupracoval s pipenv nástrojom, ktorého cieľom je priniesť do sveta Pythonu to najlepšie zo všetkých baliacich nástrojov (balíkový, nebalený a správa prostredia).

## Kľúčové vlastnosti Pipfile

1. Správa prostredia: Bezproblémová spolupráca s vytváraním izolovaných prostredí virtualenv.
2. Rozlíšenie závislostí: Zvláda rozlíšenie a uzamknutie závislostí, aby sa zabezpečilo reprodukovateľné prostredie.
3. Jednoduché použitie : Užívateľsky príjemnejšia syntax v porovnaní s requirements.txt.

## Komponenty Pipfile

Typický Pipfileobsahuje:

* [packages]: Uvádza hlavné závislosti pre váš projekt.
* [dev-packages]: Uvádza vývojové závislosti pre váš projekt (napr. testovacie nástroje).
* [requires]: Určuje verziu Pythonu potrebnú pre projekt.
* [source]: Definuje zdroj, odkiaľ sa majú balíky stiahnuť (zvyčajne PyPI).

## PríkladPipfile
~~~
[[source]]
name = "pypi"
url = "https://pypi.org/simple"
verify_ssl = true

[requires]
python_version = "3.8"

[packages]
requests = "*"
flask = "==1.1.2"

[dev-packages]
pytest = "*"
~~~

## Ako používať Pipfile a pipenv

1. Nainštalujte pipenv

Najprv musíte nainštalovať, pipenvak ste tak ešte neurobili:
~~~
pip install pipenv
~~~

2. Inicializujte nový projekt

Ak chcete vytvoriť nový projekt pomocou Pipfile:
~~~
pipenv install
~~~
Tým sa vytvorí Pipfilev aktuálnom adresári.

3. Pridajte závislosti

Závislosti môžete pridať pomocou  pipenv :
~~~
pipenv install requests
pipenv install flask==1.1.2
pipenv install --dev pytest
~~~
Tieto príkazy aktualizujú Pipfile a vygenerujú súbor Pipfile.lock, ktorý uzamkne verzie vašich závislostí.

4. Aktivujte virtuálne prostredie

Aktivujte virtuálne prostredie vytvorené pipenv:
~~~
pipenv shell
~~~

5. Spustite skripty

Spustite svoje skripty Python vo virtuálnom prostredí:
~~~
pipenv run python script.py
~~~

6. Reprodukujte životné prostredie

Ak chcete reprodukovať rovnaké prostredie na inom počítači, použite Pipfile a Pipfile.lock:
~~~
pipenv install --ignore-pipfile
~~~
To zaisťuje, že závislosti sú nainštalované presne tak, ako je uvedené v súbore Pipfile.lock.

## Výhody používania Pipfile a pipenv

* Zjednodušené riadenie závislostí : Jasne oddeľuje vývojové a výrobné závislosti.

* Reprodukovateľnosť : Súbor zámku zaisťuje konzistentné prostredia na rôznych počítačoch.

* Vylepšené zabezpečenie : Používa overenie hash na zabezpečenie integrity balíka.

* Kompatibilita : Funguje dobre s existujúcimi pracovnými postupmi, pretože v prípade potreby requirements.txt môžete z Pipfile.lock vygenerovať requirements.txt 
~~~
pipenv lock -r > requirements.txt
~~~
Používanie Pipfile a pipenv zjednodušenie správy závislostí v projektoch Pythonu, čím sa zaistí spoľahlivejšie a reprodukovateľnejšie prostredia.

>###POZNATKY z vývoja
**1./**
Ak sa vyskytol **problém s názvami kontajnerov** špecifikovanými vo vašich docker exec príkazoch. Chybové hlásenie „Žiadny takýto kontajner“ znamená, že Docker nemôže nájsť kontajnery s názvom dbalebo postgres.

Na základe výstupu z *docker ps*, to môže vyzerať tak, že názvy našich kontajnerov pre databázu PostgreSQL je napr. *docker-django-db-1* a *docker-django-db-admin-1* a kontajner pgAdmin.

Preto skúsme spustiť docker exec príkazy so správnymi názvami kontajnerov aby sme sa presvedčili či to tak je:
~~~
docker exec -it docker-django-db-1 psql -U postgres
~~~
**Tento príkaz by vás mal pripojiť ku kontajneru databázy PostgreSQL.** 

Podobne pre pgAdmin:
~~~
docker exec -it docker-django-db-admin-1 psql -U postgres
~~~
Ak sa kontajnery líšia, je potrebné ich nahradiť skutočnými názvami ktoré sú v našom prípade *docker-django-db-1* a *docker-django-db-admin-1*.

V DATABASES settings.py zmenit 'HOST': 'localhost', na 'HOST': 'docker-django-db-1', 

>###Dockerfile
je od pôvodného urobená táto nahrada:
~~~
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev
~~~
kde:
* apk update aktualizuje index balíkov.
* apk add --virtual build-deps nainštaluje závislosti zostavenia potrebné na inštaláciu balíkov Python a klientskych knižníc PostgreSQL.
* postgresql-dev sa používa na inštaláciu vývojových knižníc PostgreSQL, ktoré obsahujú potrebné hlavičkové súbory potrebné na zostavenie balíkov Python, ktoré sú prepojené s PostgreSQL.


>###Po aktualizácii súboru Docker je potrebné znova vytvoriť image Docker:
~~~
docker build -t django-docker:0.0.1 .
~~~
Potom skúste znova spustiť kontajner Docker príkazom:
~~~
docker run -p 8001:8001 django-docker:0.0.1
~~~
Toto je postup keď nepoužijeme na to súbor *docker-django.yml* a mala by sa tým vyriešiť chyba „Žiadny takýto súbor alebo adresár“ v dôsledku čoho by sa naša aplikácia Django mala úspešne spustiť v kontajneri Docker.

>###Ak sa počas procesu zostavovania Dockera v súvislosti s inštaláciou balíka došlo k chybe psycopg2-binary. 

Tak chybové hlásenie naznačuje, že pg_config spustiteľný súbor sa nenašiel, čo je potrebné na zostavenie psycopg2 zo zdroja.

Tu je niekoľko krokov, ktoré môžete podniknúť na vyriešenie tohto problému:

1. Inštalovať libpq-dev : pg_config zvyčajne sa dodáva v libpq-dev balíku. Pred spustením ho môžete nainštalovať do súboru Dockerfile pip install:
~~~
FROM python:3.6.7-alpine

RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

WORKDIR /code

ADD requirements.txt /code/
RUN pip install -r requirements.txt

ADD ./ /code/

CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]

~~~
Pridanie postgresql-dev do obrazu Docker poskytuje potrebné vývojové súbory na vytváranie balíkov Pythonu, ako je psycopg2.

2. Použiť psycopg2-binary : Prípadne môžete upraviť svoj requirements.txtsúbor tak, aby sa používal psycopg2-binarynamiesto psycopg2. psycopg2-binaryje vopred zostavený balík a nevyžaduje kompiláciu.Aktualizácia requirements.txt:
~~~
Django>=2.1
psycopg2-binary
~~~
Potom znova vytvorte svoj obrázok Docker.
Vyberte si jedno z vyššie uvedených riešení podľa svojich preferencií. Ak stále máte problémy alebo máte ďalšie otázky, neváhajte sa opýtať!

>###Ak Docker nedokáže nájsť súbor manage.py v kontajneri. 
Zabezpečme, aby bola štruktúra adresára správne skopírovaná do obrazu Docker. Uistite sa, že štruktúra vášho projektu vyzerá takto:
~~~
DOCKER-DJANGO
├── env
├── mysite
│   ├── __init__.py
│   ├── settings.py
│   ├── urls.py
│   └── wsgi.py
├── Dockerfile
├── manage.py
└── ...
~~~

Ak sa štruktúra vášho projektu líši alebo ak manage.py sa nachádza v inom adresári, musíte príslušne upraviť súbor Dockerfile.

Za predpokladu , že manage.py sa váš Dockerfile nachádza vo vnútri adresára mysite ktorý je adresárom projektu, tak Dockerfile by mal vyzerať takto:

~~~
FROM python:3.6.7-alpine

# Set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# Install dependencies
RUN apk update \
    && apk add postgresql-dev gcc python3-dev musl-dev

# Set working directory
WORKDIR /code

# Copy project files
COPY mysite/ /code/

# Install dependencies
COPY requirements.txt /code/
RUN pip install -r requirements.txt

# Expose port
EXPOSE 8001

# Run the application
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]
~~~

Pomocou súboru Dockerfile sa adresár mysite obsahujúci manage.py a ďalšie súbory projektu Django sa pri vytváraní image Docker skopíruje do adresára /code .

>### Používané príkazy
$ pip install virtualenv
$ virtualenv env
$ . env/scripts/activate
$ pip install Django>=2.1
$ echo 'Django>=2.1' >> requirements.txt
$ git add . a commit -m "komentar"
$ django-admin startproject mysite .
$ echo ".vscode/" >> .gitignore
$ docker build
$ docker-compose up
$ docker run -p 8001:8001 docker-django:0.0.1

meno/heslo:
pre postgres - postgres/postgres , meno Db je postgres a host je localhost alebo docker-django-db-1

pre prihlasenie do kontajnera pgAdmin4 - tokos@comto.sk/admin
? po restarte projektu je treba sa vždy prihlásiť ?

pre superuser-a
- admin/admin , mail je info@comto.sk


## Pridanie viacerých príkazov (v tomto kontexte sa neodporúča)

Ak potrebujete spustiť viacero príkazov postupne (hoci to nie je potrebné pre vaše aktuálne nastavenie), môžete to urobiť takto:
~~~
version: '3'

services:
  web:
    build: .
    command: /bin/bash -c "python manage.py runserver 0.0.0.0:8001 && gunicorn mysite.wsgi --bind 0.0.0.0:8001"
    ports:
      - "8001:8001"
    volumes:
      - .:/code
    networks:
      - backend
    env_file:
      - .env  # Use .env file
    depends_on:
      - db
    environment:
      - ALLOWED_HOSTS=localhost,127.0.0.1
      - DEBUG=False
      - DJANGO_DB_HOST=db

  db:
    image: postgres:latest
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data  # uchova data
    networks:
      - backend

  db-admin:
    image: dpage/pgadmin4
    environment:
      PGADMIN_DEFAULT_EMAIL: ${PGADMIN_DEFAULT_EMAIL}
      PGADMIN_DEFAULT_PASSWORD: ${PGADMIN_DEFAULT_PASSWORD}
    ports:
      - "8080:80"
    depends_on:
      - db
    volumes:
      - pgadmin_data:/var/lib/pgadmin  # uchova data
    networks:
      - backend

  nginx:
    image: nginx:latest
    ports:
      - "8088:80"
    networks:
      - backend    

networks:
  backend:
    driver: bridge

volumes:
  postgres_data:
  pgadmin_data:
~~~

V tomto nastavení by sa oba príkazy spúšťali **postupne, čo nie je praktické na spustenie servera**. Tento príklad je len na ilustráciu toho, ako môžete v prípade potreby reťaziť príkazy.


