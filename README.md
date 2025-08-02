# Pi Mail Print
This script will fetch your mailbox and print the attachments to the default printer on your system. If it contains a .docx file it will be converted to PDF and it will be printed. If it contains no attachments it will print just the e-mail.

It is strongly advised to create a special e-mail address which is private and is only used for the purpose because it will print every e-mail.

You can configure the IMAP configuration during setup or edit the `fetchmail.conf` manually

## Install

```sh
bash <(curl --silent https://raw.githubusercontent.com/kerkenit/pimailprint/refs/heads/main/setup.sh)
```

## Configure
```sh
nano /home/$(whoami)/pimailprint
```

## Create Cronjob
```cron
*       6-23    *       *       *       /home/$(whoami)/pimailprint/printmail.sh >> /var/log/printmail.log 2>&1
```

### Disclaimer
![environmental responsibility](https://s3.amazonaws.com/images.wisestamp.com/widgets/green_32.png)

$${\color{green}Please \space consider \space your \space environmental \space responsibility. \space Before \space sending \space this \space mail \space message \space to \space this \space service, \space ask \space yourself \space whether \space you \space really \space need \space a \space hard \space copy.}$$