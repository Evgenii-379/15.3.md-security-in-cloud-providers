output "bucket_url" {
  description = "Публичная ссылка на картинку из Object Storage"
  value       = "https://${var.bucket_name}.storage.yandexcloud.net/image.jpg"
}

output "nlb_ip" {
  description = "Внешний IP адрес сетевого балансировщика (NLB)"
  value = tolist([
    for listener in yandex_lb_network_load_balancer.nlb.listener :
    tolist([for spec in listener.external_address_spec : spec.address])[0]
  ])[0]
}

output "kms_key_id" {
  description = "ID ключа KMS для шифрования"
  value       = yandex_kms_symmetric_key.object_key.id
}
