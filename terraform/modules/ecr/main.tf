resource "aws_ecr_repository" "this" {
  for_each = var.repositories

  name                 = each.value
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
    kms_key         = var.kms_key_arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = each.value
    }
  )
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = var.lifecycle_policy != null ? var.repositories : []

  repository = aws_ecr_repository.this[each.value].name
  policy     = var.lifecycle_policy
}
