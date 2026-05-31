import SwiftUI

struct ReviewScreen: View {
    @Environment(AppEnvironment.self) private var env
    @Environment(SessionStore.self) private var sessionStore

    var bookingId: Booking.ID

    @State private var detail: BookingDetail?
    @State private var existingReview: Review?
    @State private var rating = 5
    @State private var communicationRating = 5
    @State private var professionalismRating = 5
    @State private var publicComment = ""
    @State private var privateFeedback = ""
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let detail {
                headerSection(detail)

                if let existingReview {
                    submittedSection(existingReview)
                } else if detail.booking.status == .completed {
                    formSections
                } else {
                    Section {
                        Label("Reviews open after check-out.", systemImage: "clock")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isLoading {
                ProgressView("Loading review")
            } else {
                ProgressView("Loading review")
            }

            if let errorMessage {
                Section {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                }
            }
        }
        .navigationTitle("Review")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                DemoSwitcherMenu()
            }
        }
        .refreshable {
            await load()
        }
        .task(id: bookingId) {
            await load()
        }
    }

    private func headerSection(_ detail: BookingDetail) -> some View {
        Section {
            VStack(alignment: .leading, spacing: 10) {
                Text(reviewTitle(for: detail))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.notifEyesInk)

                Text(detail.shift.startsAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                StatusBadge(text: detail.booking.status.displayName, color: detail.booking.status == .completed ? Color.notifEyesGreen : Color.notifEyesBlue)
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder
    private var formSections: some View {
        Section("Rating") {
            StarRatingPicker(title: "Overall", rating: $rating)
            StarRatingPicker(title: "Communication", rating: $communicationRating)
            StarRatingPicker(title: "Professionalism", rating: $professionalismRating)
        }

        Section("Public comment") {
            TextField("What should others know?", text: $publicComment, axis: .vertical)
                .lineLimit(3...6)
        }

        Section("Private feedback") {
            TextField("Optional note for NotifEyes", text: $privateFeedback, axis: .vertical)
                .lineLimit(2...5)
        }

        Section {
            Button {
                Task { await submit() }
            } label: {
                Label(isSubmitting ? "Submitting..." : "Submit review", systemImage: "star.fill")
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .disabled(isSubmitting)
        }
    }

    private func submittedSection(_ review: Review) -> some View {
        Section("Submitted") {
            HStack {
                Text("Overall")
                Spacer()
                RatingStars(rating: Double(review.ratingOverall))
            }

            ForEach(review.ratingSpecifics.keys.sorted(), id: \.self) { key in
                if let value = review.ratingSpecifics[key] {
                    LabeledContent(key.capitalized, value: "\(value)/5")
                }
            }

            if let publicComment = review.publicComment, !publicComment.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Public comment")
                        .font(.subheadline.weight(.semibold))
                    Text(publicComment)
                        .foregroundStyle(.secondary)
                }
            }

            if let privateFeedback = review.privateFeedback, !privateFeedback.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Private feedback")
                        .font(.subheadline.weight(.semibold))
                    Text(privateFeedback)
                        .foregroundStyle(.secondary)
                }
            }

            if let publishedAt = review.publishedAt {
                LabeledContent("Submitted", value: publishedAt.formatted(date: .abbreviated, time: .shortened))
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let bookingDetail = try await env.api.booking(id: bookingId)
            detail = bookingDetail

            if let role = reviewAuthor {
                existingReview = try await env.api.review(forBooking: bookingId, role: role)
            }
            errorMessage = nil
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private func submit() async {
        guard let authorRole = reviewAuthor else { return }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            _ = try await env.api.submitReview(SubmitReviewInput(
                bookingId: bookingId,
                authorRole: authorRole,
                ratingOverall: rating,
                ratingSpecifics: [
                    "communication": communicationRating,
                    "professionalism": professionalismRating
                ],
                publicComment: publicComment.trimmingCharacters(in: .whitespacesAndNewlines),
                privateFeedback: privateFeedback.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
            await load()
        } catch {
            errorMessage = userFacingMessage(for: error)
        }
    }

    private var reviewAuthor: ReviewAuthor? {
        switch sessionStore.role {
        case .od:
            return .od
        case .practice:
            return .practice
        case nil:
            return nil
        }
    }

    private func reviewTitle(for detail: BookingDetail) -> String {
        switch reviewAuthor {
        case .od:
            return "Review \(detail.practice.name)"
        case .practice:
            return "Review \(detail.optometrist.displayName ?? detail.optometrist.name)"
        case nil:
            return "Review booking"
        }
    }
}

private struct StarRatingPicker: View {
    var title: String
    @Binding var rating: Int

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { value in
                    Button {
                        rating = value
                    } label: {
                        Image(systemName: value <= rating ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(title) \(value) stars")
                }
            }
        }
    }
}
