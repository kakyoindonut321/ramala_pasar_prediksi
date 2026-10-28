-- akun baru otomatis mendapat foto profil default
alter table public.profiles
  alter column avatar_url
  set default 'https://res.cloudinary.com/ddpoqfnkx/image/upload/v1793105036/nr0jpc2prxnytxd6g2jq.jpg';

-- akun lama yang masih kosong
update public.profiles
set avatar_url = 'https://res.cloudinary.com/ddpoqfnkx/image/upload/v1793105036/nr0jpc2prxnytxd6g2jq.jpg'
where avatar_url is null;