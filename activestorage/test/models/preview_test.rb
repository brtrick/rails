# frozen_string_literal: true

require "test_helper"
require "database/setup"

class ActiveStorage::PreviewTest < ActiveSupport::TestCase
  test "previewing a PDF" do
    blob = create_file_blob(filename: "report.pdf", content_type: "application/pdf")
    preview = blob.preview(resize_to_limit: [640, 280]).processed

    assert_predicate preview.image, :attached?
    assert_equal "report.png", preview.image.filename.to_s
    assert_equal "image/png", preview.image.content_type

    image = read_image(preview.image)
    assert_equal 612, image.width
    assert_equal 792, image.height
  end

  test "previewing a cropped PDF" do
    blob = create_file_blob(filename: "cropped.pdf", content_type: "application/pdf")
    preview = blob.preview(resize_to_limit: [640, 280]).processed

    assert_predicate preview.image, :attached?
    assert_equal "cropped.png", preview.image.filename.to_s
    assert_equal "image/png", preview.image.content_type

    image = read_image(preview.image)
    assert_equal 430, image.width
    assert_equal 145, image.height
  end

  test "previewing an MP4 video" do
    blob = create_file_blob(filename: "video.mp4", content_type: "video/mp4")
    preview = blob.preview(resize_to_limit: [640, 280]).processed

    assert_predicate preview.image, :attached?
    assert_equal "video.jpg", preview.image.filename.to_s
    assert_equal "image/jpeg", preview.image.content_type

    image = read_image(preview.image)
    assert_equal 640, image.width
    assert_equal 480, image.height
  end

  test "previewing an unpreviewable blob" do
    blob = create_file_blob

    assert_raises ActiveStorage::UnpreviewableError do
      blob.preview resize_to_limit: [640, 280]
    end
  end

  test "previewing on the writer DB" do
    blob = create_file_blob(filename: "report.pdf", content_type: "application/pdf")

    # prevent_writes option is required because there is no automatic write protection anymore
    ActiveRecord::Base.connected_to(role: ActiveRecord.reading_role, prevent_writes: true) do
      blob.preview(resize_to_limit: [640, 280]).processed
    end

    assert_predicate blob.reload.preview_image, :attached?
  end

  test "preview of PDF is created on the same service" do
    blob = create_file_blob(filename: "report.pdf", content_type: "application/pdf", service_name: "local_public")
    preview = blob.preview(resize_to_limit: [640, 280]).processed

    assert_equal "local_public", preview.image.blob.service_name
  end

  test "preview of MP4 video is created on the same service" do
    blob = create_file_blob(filename: "video.mp4", content_type: "video/mp4", service_name: "local_public")
    preview = blob.preview(resize_to_limit: [640, 280]).processed

    assert_equal "local_public", preview.image.blob.service_name
  end
end
