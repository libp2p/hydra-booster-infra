locals {
  admins = toset([
    "tom.hall",
    "george.masgras",
    "mario.camou"
  ])
}

resource "aws_iam_user" "admins" {
  for_each = local.admins
  name     = each.key
}

resource "aws_iam_user_policy_attachment" "admin" {
  for_each   = aws_iam_user.admins
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
