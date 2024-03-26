import nox


@nox.session
def build(session: nox.Session):
    """
    Build the AWX Operator docsite.
    """
    session.install(
        "-r",
        "docs/requirements.in",
        "-c",
        "docs/requirements.txt",
    )
    session.run(
        "mkdocs",
        "build",
        "--strict",
        *session.posargs,
    )
