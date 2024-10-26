## 部署说明

要部署项目，请执行以下命令：

```bash
sudo  rm -r /var/www/html/telegram_update \
  && mkdir -p /var/www/html/telegram_update \
  && sudo chown -R www-data:www-data /var/www/html/telegram_update \
  && sudo chmod -R 755 /var/www/html/telegram_update \
  && sudo git clone https://github.com/smithkareng520/telegram_update_deployment.git /var/www/html/telegram_update \
  && sudo bash /var/www/html/telegram_update/setup_telegram_update.sh

