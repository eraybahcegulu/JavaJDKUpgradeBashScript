#!/bin/bash

# user input parametreleri:
# 1 /app/jdk: app için aktif olan jdk pathi
# 2 /app/jdk1.8.0_391: yeni jdk pathi, "tar -xvf jdk-8u391-linux-x64.tar.gz"
# 3 appadmin: whoami ve aktif olan jdk useri

#execute
#/app/scripts/jdk_patch.sh /app/jdk /app/jdk1.8.0_391 appadmin

# user input kontrolü
old_jdk_path=$1
new_jdk_path=$2
user=$3

# path parametre kontrolleri
if [ ! -d "$old_jdk_path" ]; then
    echo "$old_jdk_path geçersiz path"
    exit 1
fi

if [ ! -d "$new_jdk_path" ]; then
    echo "$new_jdk_path geçersiz path"
    exit 1
fi

# user parametre kontrolü
if [ "$(whoami)" != "$user" ]; then
  echo "Lütfen kullanıcı değiştir"
  exit 1
fi

# Yeni JDK ile ilişkili çalışan bir işlem var mı kontrolü- kullanıcı tarafından eski jdk pathinin yeni jdk path parametresine giriş ihtimali
new_jdk_processes=$(pgrep -f "$new_jdk_path")

if [ -n "$new_jdk_processes" ]; then
    echo "$new_jdk_path pathinde çalışan java process bulundu"
    echo "$new_jdk_processes"
    exit 1
fi

# Kullanıcı onayı alma
echo "Eski JDK Path: $old_jdk_path"
echo "Yeni JDK Path: $new_jdk_path"
read -p "Eski-Yeni JDK path onay (E/H): " confirm

if [[ "$confirm" != "E" && "$confirm" != "e" ]]; then
    echo "İptal edildi"
    exit 1
fi

# Eski JDK dizini sahipliği kontrolü
owner=$(stat -c %U "$old_jdk_path")
if [ "$owner" != "$user" ]; then
  echo "Eski JDK dizini '$old_jdk_path' '$user' kullanıcısına ait değil. Geçerli sahip: $owner."
  exit 1
fi

# Java işlemlerini sonlandırma
pids=$(pgrep -f java)
if [ -n "$pids" ]; then
    echo "$pids" | xargs -I {} echo "Sonlandırılıyor, pid: {}"
    if echo "$pids" | xargs kill -9; then
        echo "Tüm Java processleri başarıyla sonlandırıldı."
    else
        echo "Java processleri sonlandırılırken hata oluştu"
    fi
else
    echo "Çalışan Java processi bulunamadı"
fi

# cacerts dosyasını kopyalama
old_cacerts_path="$old_jdk_path/jre/lib/security/cacerts"
new_cacerts_path="$new_jdk_path/jre/lib/security/cacerts"

cp "$old_cacerts_path" "$new_cacerts_path" && echo "cacerts dosyası kopyalandı" || { echo "cacerts dosyası kopyalanırken hata oluştu"; exit 1; }

# Eski JDK'yı yedekleme
jdk_backup_current_date=$(date +"%Y-%m-%d_%H-%M-%S")
backup_path="${old_jdk_path}_${jdk_backup_current_date}_old"
mv "$old_jdk_path" "$backup_path" && echo "Eski JDK klasörü _old olarak yedeklendi." || { echo "Eski JDK klasörü yedeklenirken hata oluştu"; exit 1; }

# Yeni JDK'yı eski JDK'nın yerine taşıma
mv "$new_jdk_path" "$old_jdk_path" && echo "Yeni JDK klasörü eski JDK'nın yerine taşındı" || { echo "Yeni JDK taşınamadı"; exit 1; }

echo "JDK patch işlemi tamamlandı"