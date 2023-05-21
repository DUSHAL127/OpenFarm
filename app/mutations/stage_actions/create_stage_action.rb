module StageActions
  class CreateStageAction < Mutations::Command
    include StageActions::StageActionsConcern
    include PicturesMixin

    required do
      model :user
      string :id
      hash :attributes do
        required do
          string :name
        end
        optional do
          string :overview
          integer :order
          integer :time
        end
      end
    end

    optional do
      array :images, class: Hash, arrayize: true
    end

    def validate
      validate_stage id
      validate_images images
      validate_permissions
    end

    def execute
      @action = @stage.stage_actions.create(attributes)
      @action.save
      set_images images, @action
      @action.reload
      @action
    end

    private

    def validate_permissions
      if @stage && (@stage.guide.user != user)
        msg = 'You can only create actions for stages that belong to your '\
              'guides.'
        raise OpenfarmErrors::NotAuthorized, msg
      end
    end
  end
end
