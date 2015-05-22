module Reform
  class Form < Contract
    twin_representer_class.instance_eval do
      def default_inline_class
        Form
      end
    end

    require "reform/form/validate"
    include Validate # extend Contract#validate with additional behaviour.

    require "reform/form/populator"

    module Property
      # add macro logic, e.g. for :populator.
      def property(name, options={}, &block)
        if options.delete(:virtual)
          options[:writeable] = options[:readable] = false # DISCUSS: isn't that like an #option in Twin?
        end

        definition = super # let representable sort out inheriting of properties, and so on.
        definition.merge!(deserializer: {}) unless definition[:deserializer] # always keep :deserializer per property.


        deserializer_options = definition[:deserializer]

        # TODO: make this pluggable.
        # DISCUSS: Populators should be a representable concept?

        # Populators
        # * they assign created data, no :setter (hence the name).
        # * they (ab)use :instance, this is why they need to return a twin form.
        # * they are only used in the deserializer.



        if populator = options.delete(:populate_if_empty)
          deserializer_options.merge!({instance: Populator::IfEmpty.new(populator)})
          deserializer_options.merge!({setter: nil})
        elsif populator = options.delete(:populator)
          deserializer_options.merge!({instance: Populator.new(populator)})
          deserializer_options.merge!({setter: nil}) #if options[:collection] # collections don't need to get re-assigned, they don't change.
        end


        # TODO: shouldn't that go into validate?
        if proc = options.delete(:skip_if)
          proc = Reform::Form::Validate::Skip::AllBlank.new if proc == :all_blank
          deserializer_options.merge!(skip_parse: proc)
        end

        # default:
        # add Sync populator to nested forms.
        # FIXME: this is, of course, ridiculous and needs a better structuring.
        if (deserializer_options == {} || deserializer_options.keys == [:skip_parse]) && block_given? && !options[:inherit] # FIXME: hmm. not a fan of this: only add when no other option given?
          deserializer_options.merge!({instance: Populator::Sync.new(nil), setter: nil})
        end

        definition
      end
    end
    extend Property


    require "reform/form/multi_parameter_attributes"

    require "disposable/twin/changed"
    feature Disposable::Twin::Changed

    require "disposable/twin/sync"
    feature Disposable::Twin::Sync

    require "disposable/twin/save"
    feature Disposable::Twin::Save

    require "reform/form/prepopulate"
    include Prepopulate
  end
end
