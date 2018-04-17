data "aws_region" "current" {}

output "INSTANCE_ID" {
  value = "${aws_spot_instance_request.desktop.spot_instance_id}"
}

output "INSTANCE_REGION" {
  value = "${data.aws_region.current.name}"
}
