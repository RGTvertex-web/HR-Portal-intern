-- Resume storage bucket (Section 14: private bucket, signed URLs only).
-- No public/anon storage policies are added: the backend's service-role
-- client is the only writer/reader, same trust model as the DB tables in
-- 0001 (frontend never talks to Storage directly, backend-mediated only).

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
    'resumes',
    'resumes',
    false,
    5242880, -- 5MB, keep in sync with RESUME_MAX_SIZE_MB in backend/.env
    array[
        'application/pdf',
        'application/msword',
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    ]
)
on conflict (id) do nothing;
