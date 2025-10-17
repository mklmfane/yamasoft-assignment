module "github_oidc_for_tf_plan" {
  source    = "./modules/github-oidc-role"
  role_name = "github-actions-terraform"

  # Allow only your repo and a specific ref or environment:
  subjects = [
    "repo:my-org/my-repo:ref:refs/heads/main",
    # OR: "repo:my-org/my-repo:environment:prod",
    # OR wildcards (StringLike): "repo:my-org/my-repo:ref:refs/heads/release/*",
  ]

  # Most setups do NOT need thumbprints anymore; leave null.
  # thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]

  policy_arns = [
    "arn:aws:iam::aws:policy/ReadOnlyAccess"
    # plus your backend policies (S3 state, DynamoDB lock), or use inline_policies
  ]

  inline_policies = {
    tf_state_backend = jsonencode({
      Version = "2012-10-17",
      Statement = [
        {
          Sid    = "S3State",
          Effect = "Allow",
          Action = ["s3:*"],
          Resource = [
            "arn:aws:s3:::my-tf-state-bucket",
            "arn:aws:s3:::my-tf-state-bucket/*"
          ]
        },
        {
          Sid    = "DDBLock",
          Effect = "Allow",
          Action = ["dynamodb:*"],
          Resource = "arn:aws:dynamodb:eu-central-1:123456789012:table/tf-locks"
        }
      ]
    })
  }

  tags = {
    Project = "iac"
    Owner   = "platform"
  }
}
