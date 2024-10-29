resource "aws_iam_instance_profile" "instance-profile" {
  name = "Jump-server-profile"
  role = aws_iam_role.iam-role.name
}