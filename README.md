# Oracle Cloud

Подразумевается, что имеется личная доменная зона в CloudFlare. В противном случае
необходимо удалить terraform ресурс `cloudflare_record.wireguard` из описания стейта.

```bash
# Сгенерируем ключи для подключения к серверу
ssh-keygen -t rsa -b 4096 -C ansible -f <repo_path>/ansible/.ssh-keys/ansible
cp <repo_path>/ansible/.ssh-keys/ansible.pub <repo_path>/terraform/.keys/ansible.pub
```

Далее необходимо отредактировать `<repo_path>/terraform/secrets.auto.tfvars`,
указав значения переменных из ЛК [Oracle Cloud](https://cloud.oracle.com) и CloudFlare

```bash
# Разворот виртуалки
cd <repo_path>/terraform
terraform init
terraform apply
```

Первым шагом необходимо поправить `invenotry.ini`, указав правильный адрес/домен сервера.

Рутовый пароль добавить в `group_vars/all.yaml` или вынести переменную в `host_vars` / `inventory`

```bash
# Если чистый деплой, то нужно вначале запустить плейбук создания ansible пользователя
# которому добавится сгенерированный ключ. При запуске нужен пароль от рута
ansible-playbook -k -e "target=wireguard ansible_ssh_user=root" path/to/playbook -t ansible_user
# После этого ansible_ssh_user не указывать и запускать без -k
ansible-playbook -e "target=wireguard" path/to/playbook

# При первом деплое можно обновить систему, для этого запустить пайплайн
# с указанием тега run_upgrade (по умолчанию обновление системы скипается)
ansible-playbook -e "target=wireguard" path/to/playbook -t all,run_upgrade
```
