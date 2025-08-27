@export()
type environmentType = 'dev' | 'test' | 'prod'

@export()
type tagsType = {
  environment: string
  project: string
  owner: string
  costCenter: string
  deployedBy: string
}
