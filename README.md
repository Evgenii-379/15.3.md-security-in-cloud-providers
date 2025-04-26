# Домашнее задание к занятию «Безопасность в облачных провайдерах»-***Вуколов Евгений***  
 
Используя конфигурации, выполненные в рамках предыдущих домашних заданий, нужно добавить возможность шифрования бакета.
 
---
## Задание 1. Yandex Cloud   
 
1. С помощью ключа в KMS необходимо зашифровать содержимое бакета:
 
 - создать ключ в KMS;
 - с помощью ключа зашифровать содержимое бакета, созданного ранее.
2. (Выполняется не в Terraform)* Создать статический сайт в Object Storage c собственным публичным адресом и сделать доступным по HTTPS:
 
 - создать сертификат;
 - создать статическую страницу в Object Storage и применить сертификат HTTPS;
 - в качестве результата предоставить скриншот на страницу с сертификатом в заголовке (замочек).
 
Полезные документы:
 
- [Настройка HTTPS статичного сайта](https://cloud.yandex.ru/docs/storage/operations/hosting/certificate).
- [Object Storage bucket](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/storage_bucket).
- [KMS key](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/kms_symmetric_key).
 
--- 
## Задание 2*. AWS (задание со звёздочкой)
 
Это необязательное задание. Его выполнение не влияет на получение зачёта по домашней работе.
 
**Что нужно сделать**
 
1. С помощью роли IAM записать файлы ЕС2 в S3-бакет:
 - создать роль в IAM для возможности записи в S3 бакет;
 - применить роль к ЕС2-инстансу;
 - с помощью bootstrap-скрипта записать в бакет файл веб-страницы.
2. Организация шифрования содержимого S3-бакета:
 
 - используя конфигурации, выполненные в домашнем задании из предыдущего занятия, добавить к созданному ранее бакету S3 возможность шифрования Server-Side, используя общий ключ;
 - включить шифрование SSE-S3 бакету S3 для шифрования всех вновь добавляемых объектов в этот бакет.
 
3. *Создание сертификата SSL и применение его к ALB:
 
 - создать сертификат с подтверждением по email;
 - сделать запись в Route53 на собственный поддомен, указав адрес LB;
 - применить к HTTPS-запросам на LB созданный ранее сертификат.
 
Resource Terraform:
 
- [IAM Role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role).
- [AWS KMS](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key).
- [S3 encrypt with KMS key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_object#encrypting-with-kms-key).
 
Пример bootstrap-скрипта:
 
```
#!/bin/bash
yum install httpd -y
service httpd start
chkconfig httpd on
cd /var/www/html
echo "<html><h1>My cool web-server</h1></html>
```

# **Решение**

1. Создание KMS-ключа и его применение к Object Storage. При помощи Terraform создаю ключ KMS, который позже применяется при загрузке объектов с помощью s3 cp --sse-c.
 Добавляю блок создания ключа KMS в конфигурацию terraform предыдущего задания:

```
resource "yandex_kms_symmetric_key" "object_key" {
  name              = "bucket-encryption-key"
  default_algorithm = "AES_256"
  rotation_period   = "8760h"
  folder_id         = var.yc_folder_id
}

```

- Добавляю в outputs.tf :

```
output "kms_key_id" {
  description = "ID ключа KMS для шифрования"
  value       = yandex_kms_symmetric_key.object_key.id
}

```

- Затем применяю :

```
terraform init
terraform apply

```

- Далее шифруем с помощью KMS (SSE-KMS). Вначале уточняю ID KMS ключа

```
 terraform output kms_key_id 

```
- Установливаю aws CLI:

```
sudo apt install awscli

```

- Устанавливаю права доступа на ключ :

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20121831.png)

- Настраиваю awscli под Yandex Object Storage:

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20113504.png)

- Перезагружаю файл с шифрованием через KMS:

``` 
aws --profile yandex \
--endpoint-url=https://storage.yandexcloud.net \
s3 cp image.jpg s3://my-bucket-evgen/image.jpg \
--sse aws:kms \
--sse-kms-key-id "abjrtup8e93e4irmb16b"

```

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20121857.png)

Файл будет перезаписан, но уже зашифрован через KMS.


2. Создание статического сайта в Object Storage.
- Создаю файл index.html локально на своём компьютере, где будет находится статическая страница:

```
<!DOCTYPE html>
<html lang="ru">
<head>
  <meta charset="UTF-8">
  <title>Мой статический сайт</title>
</head>
<body>
  <h1>Добро пожаловать на мой сайт!</h1>
  <img src="https://my-bucket-evgen.storage.yandexcloud.net/image.jpg" width="30%">
</body>
</html>

```
- Загружаю index.html в бакет :

```
aws --profile yandex \
--endpoint-url=https://storage.yandexcloud.net \
s3 cp index.html s3://my-bucket-evgen/index.html --acl public-read

```

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20141642.png)

- Настраиваю бакет как статический сайт на странице в Yandex Cloud.
Yandex Cloud уже автоматически обеспечивает базовый HTTPS для доменов вида .website.yandexcloud.net

- Захожу на сайт по ссылке : 

```
https://my-bucket-evgen.website.yandexcloud.net/

```

- Сайт загрузился с моей надписью "Добро пожаловать на мой сайт!", но картинка не загрузилась так как файл был зашифрован через KMS.
Поэтому я удаляю зашифрованный файл image.jpg из бакета и загружаю картинку заново, но без шифрования ( делаю её публичной):


- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20164752.png)

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20165021.png)

- Снова захожу в браузере по ссылке https://my-bucket-evgen.website.yandexcloud.net/, теперь картинка загружается и в строке запросов виден замочек,
То есть статический сайт размещён на Object Storage, доступен по HTTPS через стандартный сертификат Яндекс.

- ![scrin](https://github.com/Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/Снимок%20экрана%202025-04-26%20165131.png)


- Ссылки на манифесты :

[main.tf](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/main.tf)

[index.html](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/index.html)

[outputs.tf](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/outputs.tf)

[ssh_keys.tf](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/ssh_keys.tf)

[terraform.tfvars](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/terraform.tfvars)

[variables.tf](Evgenii-379/15.3.md-security-in-cloud-providers/blob/main/config/variables.tf)







































