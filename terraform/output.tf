data "aws_region" "current" {}

output "INSTANCE_ID" {
  value = "${aws_instance.desktop.id}"
}

output "INSTANCE_REGION" {
  value = "${data.aws_region.current.name}"
}
