module EffectiveLogging
  module ActiveStorageLogger

    def track_downloads
      user = current_user if respond_to?(:current_user)

      key = decode_verified_key()
      return unless key.present?

      blob = ActiveStorage::Blob.where(key: key[:key]).first
      return unless blob.present?

      blob.attachments.each do |attachment|
        associated = attachment.record
        filename = blob.filename.to_s
        message = [associated.to_s, filename.to_s].uniq.join(' ')

        EffectiveLogger.download(message, associated: associated, filename: filename, user: user)
      end
    end

  end
end
