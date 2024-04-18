- [antispambox](#antispambox)
  - [Using the container](#using-the-container)
    - [Build the container](#build-the-container)
    - [IMAP config file and other details](#imap-config-file-and-other-details)
      - [IMAP Config properties](#imap-config-properties)
      - [Updating the configuration file](#updating-the-configuration-file)
    - [Starting the container](#starting-the-container)
    - [Train spamassassin and spamd](#train-spamassassin-and-spamd)
    - [Hints](#hints)
  - [License](#license)


# antispambox
**IMPORTANT:** This is a re-packaged version of the original _[antispambox](https://github.com/rsmuc/antispambox)_ with some small changes:

- Files in the repo were re-organized.
- The original code and configuration files are the SAME but the base image docker image was pinned to `debian:bullseye-slim` to allow the original code to run as originally designed.
- A docker compose file was included to make it easier to run.
- The imap_accounts file is now set as a docker compose secret.

Please take a look at the original repo to see the list of features and other important information: [https://github.com/rsmuc/antispambox](https://github.com/rsmuc/antispambox)

## Using the container

### Build the container

```bash
docker compose build
```

### IMAP config file and other details

By defaul the IMAP config file is located inside this repo at the following path:

- `source/files/config/secrets/imap_accounts.json`

And the default configuration looks like this:

```json
{
  "antispambox": {
    "enabled": "False",
    "account": {
      "server": "imap.example.net",
      "user": "username",
      "password": "examplepassword",
      "junk_folder": "Junk",
      "inbox_folder": "INBOX",
      "ham_train_folder": "HAM",
      "spam_train_folder": "SPAMTrain",
      "spam_train_folder2": "SPAMTrain"
    }
  }
}
```

#### IMAP Config properties
- `antispambox.enabled`: Set to `True` to enable the scanning for spam. Defaults to `False`.
- `antispambox.account.server`: IMAP server host name.
- `antispambox.account.user`: IMAP account user name.
- `antispambox.account.password`: IMAP account password.
- `antispambox.account.junk_folder`: Junk or Spam folder.
- `antispambox.account.inbox_folder`: Inbox folder.
- `antispambox.account.ham_train_folder`: HAM folder to train spamassassin and spamd.
- `antispambox.account.spam_train_folder`: SPAM folder to train spamassassin.
- `antispambox.account.spam_train_folder2`: SPAM folder to train spamd.

#### Updating the configuration file

1. Make sure to update the `imap_accounts.json` file before you run the container.
2. To enable the scanning for spam, you need to set the `antispambox.enabled` property to `True`.
3. You might be able to start the container with the `antispambox.enabled` flag set to `False` BUT the scannning will be disabled and you will required to stop the container and edit the files.

### Starting the container

```bash
docker compose up -d
```

### Train spamassassin and spamd

**IMPORTANT:**

- To ensure that spamassassin and spamd bayes filtering is working you should train it at least with 200 SPAM and 200 HAM mails.
- To train the backends copy your SPAM and HAM messages in the IMAP folders you configured for SPAM_train and HAM_traing.
- Mails you move manually to SPAM_train will be learned as SPAM. Mails you move manually to HAM_train will learned as HAM. The backend services spamassassin and rspamd will learn and improve their detection rate with each learned mail.

### Hints

- To access the running container use: `docker exec -i -t antispambox /bin/bash`
- To see how many mails rspamd has already learned or detected as SPAM or HAM, just run: `spamc stat`
- To see how many mails spamassassin has already learned run: `sa-learn --dump magic`.
- to see the IMAP idle and scanning process check: `/var/log/antispambox.log`

## License

MIT

see license text














