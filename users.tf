locals {
  admins = toset([
    "tom.hall",
    "george.masgras",
    "mario.camou"
  ])

  read_only = toset([
    "dennis-tra" # User in Fil slack, gus/will asked for him to be added
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

resource "aws_iam_user" "read_only" {
  for_each = local.read_only
  name     = each.key
}

resource "aws_iam_user_policy_attachment" "read_only" {
  for_each   = aws_iam_user.read_only
  user       = each.value.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBReadOnlyAccess"
}
